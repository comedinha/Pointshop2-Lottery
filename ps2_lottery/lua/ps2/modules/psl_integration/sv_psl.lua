PSLottery = {}
lastwinners = {}
numberwinners = {}

PSLottery.MaxValue = 75
PSLottery.TicketPrice = 100
PSLottery.StartingJackpot = 1000
PSLottery.Persistent = true
PSLottery.MaxTickets = 2
PSLottery.PointsName = "points"
PSLottery.lastNumber = 0
PSLottery.RoundsLeft = 10

util.AddNetworkString("LotteryMenu")
util.AddNetworkString("TicketBuy")

print("PointShop Lottery Initialized")

if !file.Exists( "lottery/jackpot.txt", "DATA" ) then
	file.Write( "lottery/jackpot.txt", PSLottery.StartingJackpot )
end
local PersistentJackpot = tonumber(file.Read("lottery/jackpot.txt", "DATA"))

if !file.Exists( "lottery/lastnumber.txt", "DATA" ) then
	file.Write( "lottery/lastnumber.txt", PSLottery.lastNumber )
end
local LastNumber = tonumber(file.Read("lottery/lastnumber.txt", "DATA"))

if file.Exists( "lottery/lastwinners.txt", "DATA" ) then
	lastwinners = util.JSONToTable(file.Read("lottery/lastwinners.txt", "DATA"))
end

if !file.Exists( "lottery/commonnumber.txt", "DATA" ) then
	for a = 1, PSLottery.MaxValue + 1 do
		table.insert(numberwinners, a, 1)
	end
	file.Write("lottery/commonnumber.txt", util.TableToJSON(numberwinners))
end
local WinnerNumbers = util.JSONToTable(file.Read("lottery/commonnumber.txt", "DATA"))

PSLottery.Number = 0
PSLottery.Tickets = {}
PSLottery.TicketNumber = 0
PSLottery.Participants = 0
PSLottery.CanBuy = false
PSLottery.Winrars = {}
PSLottery.WinrarsNumber = 0

if (PSLottery.Persistent) then
	PSLottery.Jackpot = PersistentJackpot
else
	PSLottery.Jackpot = PSLottery.StartingJackpot
end

timer.Create( "LotteryTick", 1, 0, function() PSLottery:LotteryTick() end )
timer.Create("LotterySave", 60, 0, function() file.Write( "lottery/jackpot.txt", PSLottery.Jackpot ) end )
timer.Create( "LotteryInfos", 1, 0, function() PSLottery:LotteryInfos() end )

function PSLottery:StartUp()
	self.Tickets = {}
	self.TicketNumber = 0
	self.Participants = 0
	self.Winrars = {}
	self.WinrarsNumber = 0
	self.WinrarsNumber = 0
	self:GenerateNumeber()
	for k,v in pairs(player.GetAll()) do
		v:SetNWInt("TicketsBought",0)
	end
	self.CanBuy = true
end

function PSLottery:LotteryTick()
	self:StartUp()
	timer.Destroy( "LotteryTick" )
end

function PSLRoundStart()
	if PSLottery.RoundsLeft > 0 then
		PSLottery.RoundsLeft = PSLottery.RoundsLeft - 1
	end
end

function PSLRoundEnd()
	if PSLottery.RoundsLeft == 1 then
		PSLottery.RoundsLeft = PSLottery.RoundsLeft - 1
		PSLottery.CanBuy = false
		PSLottery:Drawing()
	end
	PSLottery:Message()
end

hook.Add("TTTPrepareRound", "PSLTTTRoundInitiateHook", PSLRoundStart) -- TTT Round Start
hook.Add("TTTEndRound", "PSLTTTRoundEndHook", PSLRoundEnd) -- TTT Round End

function PSLottery:LotteryInfos()
	for k,v in pairs(player.GetAll()) do
		net.Start( "LotteryMenu" )
			net.WriteInt(PSLottery.TicketPrice, 16)
			net.WriteInt(PSLottery.MaxTickets, 16)
			net.WriteInt(PSLottery.RoundsLeft, 16)
			net.WriteInt(PSLottery.Jackpot, 32)
			net.WriteInt(LastNumber, 16)
			net.WriteInt(PSLottery.Participants, 16)
			net.WriteTable(lastwinners)
			net.WriteTable(WinnerNumbers)
		net.Send( v )
	end
end

function PSLottery:GenerateNumeber()
	self.Number = math.random(0, self.MaxValue)
end

function PSLottery:Drawing()
	timer.Destroy( "LotteryMessage")
	for k,v in pairs(self.Tickets) do
		if (v.NumberChosen == self.Number) then
			self.WinrarsNumber = self.WinrarsNumber + 1
			self.Winrars[self.WinrarsNumber] = {}
			self.Winrars[self.WinrarsNumber].Name = v.PlayerEnt
			self.Winrars[self.WinrarsNumber].BuyDate = v.BuyDate
		end
	end
	file.Write( "lottery/lastnumber.txt", self.Number )
	table.insert(WinnerNumbers, self.Number + 1, WinnerNumbers[self.Number] + 1)
	file.Write("lottery/commonnumber.txt", util.TableToJSON(WinnerNumbers))
	if (self.WinrarsNumber > 0) then
		self:Winrar()
	else
		for k,v in pairs(player.GetAll()) do
			v:PrintMessage( HUD_PRINTTALK , "Lottery: O número vencedor é "..self.Number)
			v:PrintMessage( HUD_PRINTTALK , "Lottery: Ninguém ganhou! O premio está em "..self.Jackpot.." "..self.PointsName.."!")
		end
	end
	file.Write( "lottery/jackpot.txt", self.Jackpot )
end

function PSLottery:Winrar()
	local PlayerPayout = self.Jackpot / self.WinrarsNumber
	self.Jackpot = self.StartingJackpot
	file.Write( "lottery/jackpot.txt", self.Jackpot )
	for k,v in pairs(self.Winrars) do
		v.Name:PS2_AddStandardPoints(PlayerPayout, "Ganhador da Loteria!!!", true, true)
		local winnerset = {name = v.Name:Name(), number = self.Number, value = PlayerPayout, windate = os.date("%d/%m/%Y as %X", v.BuyDate)}
		table.insert(lastwinners, 1, winnerset)
		if table.Count(lastwinners) > 10 then
			table.remove(lastwinners)
		end
		file.Write("lottery/lastwinners.txt", util.TableToJSON(lastwinners))
		for i,p in pairs(player.GetAll()) do
			p:PrintMessage( HUD_PRINTTALK , "Lottery: O número vencedor é "..self.Number)
			p:PrintMessage( HUD_PRINTTALK , "Lottery: O jogador '"..v.Name:Name().."' Ganhou!!!, e recebeu "..PlayerPayout.." "..self.PointsName.."!")
		end
	end
end

function PSLottery:AddTicket(ply, number)
	self.TicketNumber = self.TicketNumber + 1
	self.Participants = self.Participants + 1
	self.Tickets[self.TicketNumber] = {}
	self.Tickets[self.TicketNumber].PlayerEnt = ply
	self.Tickets[self.TicketNumber].NumberChosen = number
	self.Tickets[self.TicketNumber].BuyDate = os.time()
	self.Jackpot = self.Jackpot + self.TicketPrice
	umsg.Start("LotteryMessage", ply)
		umsg.String("Você comprou o ticket numero "..number)
	umsg.End()
end

function PSLottery:CheckNumber(ply, number)
	if (number != nil && (number >= 0 && number <= PSLottery.MaxValue)) then
		if (ply:PS2_GetWallet().points >= PSLottery.TicketPrice) then
			local IsGood = true
			for k,v in pairs(PSLottery.Tickets) do
				if (v.PlayerEnt == ply && v.NumberChosen == number) then
					IsGood = false
					break;
				end
			end
			if (IsGood) then
				if (PSLottery.CanBuy) then
					if (ply:GetNWInt("TicketsBought") < PSLottery.MaxTickets) then
						ply:PS2_AddStandardPoints(-PSLottery.TicketPrice, "Lottery Ticket", true, true)
						PSLottery:AddTicket(ply, number)
						ply:SetNWInt("TicketsBought", (ply:GetNWInt("TicketsBought") +1))
					else
						umsg.Start("LotteryMessage", ply)
							umsg.String("Você comprou o máximo de tickets, espere o próximo sorteio.")
						umsg.End()
					end
				else
					umsg.Start("LotteryMessage", ply)
						umsg.String("Você não pode comprar tickets agora, por favor espere o próximo mapa.")
					umsg.End()
				end
			else
				umsg.Start("LotteryMessage", ply)
					umsg.String("Você não pode comprar duas vezes o mesmo numero!")
				umsg.End()
			end
		else
			umsg.Start("LotteryMessage", ply)
				umsg.String("Você não tem "..PSLottery.TicketPrice.." "..PSLottery.PointsName.." para comprar o ticket!")
			umsg.End()
		end
	else
		umsg.Start("LotteryMessage", ply)
			umsg.String("Digite um número entre 0 e "..PSLottery.MaxValue)
		umsg.End()
	end
end

function PSLottery:Message()
	if PSLottery.CanBuy == false then
		return
	end
	
	local roundsleftmsg = "O sorteiro será realizado ao final do round."
	if PSLottery.RoundsLeft == 2 then
		roundsleftmsg = "O sorteiro será no próximo round."
	elseif PSLottery.RoundsLeft > 2 then
		roundsleftmsg = "O próximo sorteio é em "..PSLottery.RoundsLeft.." rounds."
	end
	
	for k,v in pairs(player.GetAll()) do
		v:PrintMessage( HUD_PRINTTALK , "Lottery: "..roundsleftmsg)
		v:PrintMessage( HUD_PRINTTALK , "O prémio está em "..PSLottery.Jackpot.." "..PSLottery.PointsName.."")
		v:PrintMessage( HUD_PRINTTALK , "Para jogar digite vá até o pointshop e clique na categoria lottery.")
	end
end

function PlayerLeavesServer( ply )
	for k,v in pairs(PSLottery.Tickets) do
		if (v.PlayerEnt == ply) then
			v.NumberChosen = -1
		end
	end
end
hook.Add( "PlayerDisconnected", "PSLplayerleavesserver", PlayerLeavesServer )

net.Receive( "LotteryMenu", function( len )
	local ply = net.ReadEntity()
	local number = net.ReadInt(16)
	PSLottery:CheckNumber(ply, number)
end )