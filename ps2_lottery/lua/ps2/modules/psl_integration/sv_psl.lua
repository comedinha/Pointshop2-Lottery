if !PSLottery then PSLottery = {} end
if !Translate then Translate = {} end

include("sh_translations.lua")

PSLottery.MaxValue = 75
PSLottery.TicketPrice = 100
PSLottery.StartingJackpot = 1000
PSLottery.MaxTickets = 2
PSLottery.PointsName = "points"
PSLottery.RoundsLeft = 10

util.AddNetworkString("LotteryInfos")
util.AddNetworkString("LotteryBuy")
util.AddNetworkString("LotteryRoundEnd")
util.AddNetworkString("LotteryDrawing")
util.AddNetworkString("LotteryMenu")
util.AddNetworkString("LotteryMessage")

if not file.Exists( "lottery/jackpot.txt", "DATA" ) then
	file.Write( "lottery/jackpot.txt", PSLottery.StartingJackpot )
end
PSLottery.Jackpot = tonumber(file.Read("lottery/jackpot.txt", "DATA")) or PSLottery.StartingJackpot

if not file.Exists( "lottery/lastnumber.txt", "DATA" ) then
	file.Write( "lottery/lastnumber.txt", PSLottery.lastNumber )
end
PSLottery.lastNumber = tonumber(file.Read("lottery/lastnumber.txt", "DATA")) or 0

if not file.Exists( "lottery/lastwinners.txt", "DATA" ) then
	PSLottery.LastWinners = {}
	file.Write( "lottery/lastwinners.txt", PSLottery.LastWinners )
end
PSLottery.LastWinners = util.JSONToTable(file.Read("lottery/lastwinners.txt", "DATA")) or {}

if not file.Exists( "lottery/commonnumber.txt", "DATA" ) then
	for a = 1, PSLottery.MaxValue + 1 do
		PSLottery.WinnerNumbers = {}
		table.insert(PSLottery.WinnerNumbers, a, 1)
	end
	file.Write("lottery/commonnumber.txt", util.TableToJSON(PSLottery.WinnerNumbers))
end
PSLottery.WinnerNumbers = util.JSONToTable(file.Read("lottery/commonnumber.txt", "DATA")) or 0

PSLottery.Number = 0
PSLottery.Tickets = {}
PSLottery.TicketNumber = 0
PSLottery.Participants = 0
PSLottery.CanBuy = false
PSLottery.Winrars = {}
PSLottery.WinrarsNumber = 0

hook.Add( "OnGamemodeLoaded", "PSLottery_StartUp", function()
	PSLottery.CanBuy = true
end)

hook.Add("PlayerInitialSpawn", "SendInitialData", function(ply) 
	timer.Simple( 3, function()
		PSLottery:LotteryInfos(1, ply)
	end)
end)

hook.Add("TTTPrepareRound", "PSLTTTRoundInitiateHook", function()
	if PSLottery.RoundsLeft > 0 then
		PSLottery.RoundsLeft = PSLottery.RoundsLeft - 1
	end
end)

hook.Add("TTTEndRound", "PSLTTTRoundEndHook", function()
	local infomode = 3
	if PSLottery.RoundsLeft == 1 then
		PSLottery.RoundsLeft = PSLottery.RoundsLeft - 1
		PSLottery.CanBuy = false
		PSLottery:Drawing()
		infomode = 4
	end
	PSLottery:Message()
	PSLottery:LotteryInfos(infomode)
end)

hook.Add("PlayerDisconnected", "PSLplayerleavesserver", function(ply)
	for k, v in pairs(PSLottery.Tickets) do
		if (v.PlayerEnt == ply) then
			v.NumberChosen = -1
		end
	end
end)

function PSLottery:LotteryInfos(mode, ply)
	if mode == 1 then
		net.Start("LotteryInfos")
			net.WriteInt(PSLottery.TicketPrice, 16)
			net.WriteInt(PSLottery.MaxTickets, 16)
			net.WriteInt(PSLottery.RoundsLeft, 16)
			net.WriteInt(PSLottery.Jackpot, 32)
			net.WriteInt(PSLottery.lastNumber, 16)
			net.WriteInt(PSLottery.Participants, 16)
			net.WriteTable(PSLottery.LastWinners)
		net.Send(ply)
	elseif mode == 2 then
		net.Start("LotteryBuy")
			net.WriteInt(PSLottery.Jackpot, 32)
			net.WriteInt(PSLottery.Participants, 16)
		net.Send(ply)
	elseif mode == 3 then
		net.Start("LotteryRoundEnd")
			net.WriteInt(PSLottery.RoundsLeft, 16)
			net.WriteInt(PSLottery.Jackpot, 32)
			net.WriteInt(PSLottery.Participants, 16)
		net.Broadcast()
	elseif mode == 4 then
		net.Start("LotteryDrawing")
			net.WriteInt(PSLottery.RoundsLeft, 16)
			net.WriteInt(PSLottery.Jackpot, 32)
			net.WriteInt(PSLottery.lastNumber, 16)
			net.WriteInt(PSLottery.Participants, 16)
			net.WriteTable(PSLottery.LastWinners)
		net.Broadcast()
	end
end

function PSLottery:Drawing()
	timer.Destroy( "LotteryMessage")
	self.Number = math.random(0, self.MaxValue)
	for k,v in pairs(self.Tickets) do
		if (v.NumberChosen == self.Number) then
			self.WinrarsNumber = self.WinrarsNumber + 1
			self.Winrars[self.WinrarsNumber] = {}
			self.Winrars[self.WinrarsNumber].Name = v.PlayerEnt
			self.Winrars[self.WinrarsNumber].BuyDate = v.BuyDate
		end
	end
	file.Write( "lottery/lastnumber.txt", self.Number )
	table.insert(PSLottery.WinnerNumbers, self.Number + 1, PSLottery.WinnerNumbers[self.Number] + 1)
	file.Write("lottery/commonnumber.txt", util.TableToJSON(PSLottery.WinnerNumbers))
	if (self.WinrarsNumber > 0) then
		self:Winrar()
	else
		for k,v in pairs(player.GetAll()) do
			v:PrintMessage( HUD_PRINTTALK , "Lottery: "..Translate.NumberWinner.." "..self.Number)
			v:PrintMessage( HUD_PRINTTALK , "Lottery: "..Translate.NoWinners.." "..self.Jackpot.." "..self.PointsName.."!")
		end
	end
end

function PSLottery:Winrar()
	local PlayerPayout = self.Jackpot / self.WinrarsNumber
	self.Jackpot = self.StartingJackpot
	file.Write( "lottery/jackpot.txt", self.Jackpot )
	for k,v in pairs(self.Winrars) do
		v.Name:PS2_AddStandardPoints(PlayerPayout, Translate.WinnerMsg, true, true)
		local winnerset = {name = v.Name:Name(), number = self.Number, value = PlayerPayout, windate = os.date("%d/%m/%Y as %X", v.BuyDate)}
		table.insert(PSLottery.LastWinners, 1, winnerset)
		if table.Count(PSLottery.LastWinners) > 10 then
			table.remove(PSLottery.LastWinners)
		end
		file.Write("lottery/lastwinners.txt", util.TableToJSON(PSLottery.LastWinners))
		for i,p in pairs(player.GetAll()) do
			p:PrintMessage( HUD_PRINTTALK , "Lottery: "..Translate.NumberWinner.." "..self.Number)
			p:PrintMessage( HUD_PRINTTALK , "Lottery: "..v.Name:Name().." "..Translate.Winner.." "..PlayerPayout.." "..self.PointsName.."!")
		end
	end
end

function PSLottery:LotteryMessage(ply, msg)
	net.Start("LotteryMessage")
		net.WriteString(msg)
	net.Send(ply)
end

function PSLottery:AddTicket(ply, number)
	self.TicketNumber = self.TicketNumber + 1
	self.Participants = self.Participants + 1
	self.Tickets[self.TicketNumber] = {}
	self.Tickets[self.TicketNumber].PlayerEnt = ply
	self.Tickets[self.TicketNumber].NumberChosen = number
	self.Tickets[self.TicketNumber].BuyDate = os.time()
	self.Jackpot = self.Jackpot + self.TicketPrice
	file.Write( "lottery/jackpot.txt", PSLottery.Jackpot)
	PSLottery:LotteryInfos(2, ply)
	PSLottery:LotteryMessage(ply, Translate.TicketNumber.." "..number)
end

function PSLottery:CheckNumber(ply, number)
	if (number != nil && (number >= 0 && number <= PSLottery.MaxValue)) then
		if (ply:PS2_GetWallet().points >= PSLottery.TicketPrice) then
			local IsGood = true
			for k,v in pairs(PSLottery.Tickets) do
				if (v.PlayerEnt == ply && v.NumberChosen == number) then
					IsGood = false
					break
				end
			end
			if (IsGood) then
				if (PSLottery.CanBuy) then
					if (ply:GetNWInt("TicketsBought") < PSLottery.MaxTickets) then
						ply:PS2_AddStandardPoints(-PSLottery.TicketPrice, Translate.TicketName, true, true)
						PSLottery:AddTicket(ply, number)
						ply:SetNWInt("TicketsBought", (ply:GetNWInt("TicketsBought") +1))
					else
						PSLottery:LotteryMessage(ply, Translate.TicketLimit)
					end
				else
					PSLottery:LotteryMessage(ply, Translate.CanNotBuy)
				end
			else
				PSLottery:LotteryMessage(ply, Translate.SameNumber)
			end
		else
			PSLottery:LotteryMessage(ply, Translate.NoMoney)
		end
	else
		PSLottery:LotteryMessage(ply, Translate.ExceededNumber.." "..PSLottery.MaxValue)
	end
end

function PSLottery:Message()
	if PSLottery.CanBuy == false then
		return
	end
	local roundsleftmsg = Translate.MsgEndRound
	if PSLottery.RoundsLeft == 2 then
		roundsleftmsg = Translate.MsgNextRound
	elseif PSLottery.RoundsLeft > 2 then
		roundsleftmsg = Translate.MsgRounds.." "..PSLottery.RoundsLeft.." rounds."
	end
	for k,v in pairs(player.GetAll()) do
		v:PrintMessage(HUD_PRINTTALK , "Lottery: "..roundsleftmsg)
		v:PrintMessage(HUD_PRINTTALK , Translate.MsgAward.." "..PSLottery.Jackpot.." "..PSLottery.PointsName)
	end
end

net.Receive("LotteryMenu", function(len, pl)
	local number = net.ReadInt(16)
	PSLottery:CheckNumber(pl, number)
end)