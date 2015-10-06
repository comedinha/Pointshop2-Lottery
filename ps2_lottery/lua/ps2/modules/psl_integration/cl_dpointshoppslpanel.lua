if !PSLottery then PSLottery = {} end
if !Translate then Translate = {} end

include("sh_translations.lua")

PSLottery.TicketPrice = 0
PSLottery.MaxTickets = 0
PSLottery.RoundsLeft = 0
PSLottery.Jackpot = 0
PSLottery.LastNumber = 0
PSLottery.Participants = 0
PSLottery.LastWinners = {}

function PSLottery:Init()
	self:SetSkin(Pointshop2.Config.DermaSkin)

	self.FunctionPanel = vgui.Create("DPanel", self)
	self.FunctionPanel:Dock(LEFT)
	self.FunctionPanel:DockMargin(10, 10, 15, 10)
	self.FunctionPanel:SetWide(375)
	Derma_Hook(self.FunctionPanel, "Paint", "Paint", "InnerPanel")

	self.ThreeLabel2 = vgui.Create("DLabel", self.FunctionPanel)
	self.ThreeLabel2:SetPos(15, 35)
	self.ThreeLabel2:SetFont("PS2_Normal")
	self.ThreeLabel2:SetText(Translate.LuckNumber.." ".. math.random(0, 75))
	self.ThreeLabel2:SizeToContents()

	self.InfoLabel1 = vgui.Create("DLabel", self.FunctionPanel)
	self.InfoLabel1:SetPos(15, 55)
	self.InfoLabel1:SetFont("PS2_Normal")
	self.InfoLabel1:SetText(Translate.PTicketNumber)
	self.InfoLabel1:SizeToContents()

	self.StreamEntry = vgui.Create("DTextEntry", self.FunctionPanel)
	self.StreamEntry:SetPos(15, 75)
	self.StreamEntry:SetTall(20)
	self.StreamEntry:SetWide(300)
	self.StreamEntry:SetEnterAllowed( false )

	self.SubmitButton = vgui.Create("DButton", self.FunctionPanel)
	self.SubmitButton:SetText(Translate.BuyTicket.." ("..PSLottery.TicketPrice.." points)")
	self.SubmitButton:SetPos(15, 95)
	self.SubmitButton:SetSize(300, 20)
	self.SubmitButton.DoClick = function ()
		local number = tonumber(self.StreamEntry:GetValue())
		if (!number) then number = -1 end
		net.Start( "LotteryMenu" )
			net.WriteInt(number, 16)
		net.SendToServer()
		self.StreamEntry:SetText("")
	end

	self.SeparatorPanel = vgui.Create("DPanel", self.FunctionPanel)
	self.SeparatorPanel:SetPos(0, 165)
	self.SeparatorPanel:SetTall(10)
	self.SeparatorPanel:SetWide(375)
	self.SeparatorPanel.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color( 102, 102, 102 ))
	end

	self.StaticsLabel = vgui.Create("DLabel", self.FunctionPanel)
	self.StaticsLabel:SetPos(15, 180)
	self.StaticsLabel:SetFont("PS2_MediumLarge")
	self.StaticsLabel:SetText(Translate.Statistics)
	self.StaticsLabel:SizeToContents()

	self.SeparatorPanel2 = vgui.Create("DPanel", self.FunctionPanel)
	self.SeparatorPanel2:SetPos(0, 275)
	self.SeparatorPanel2:SetTall(10)
	self.SeparatorPanel2:SetWide(375)
	self.SeparatorPanel2.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color( 102, 102, 102 ))
	end

	self.InfoLabel = vgui.Create("DLabel", self.FunctionPanel)
	self.InfoLabel:SetPos(15, 290)
	self.InfoLabel:SetFont("PS2_MediumLarge")
	self.InfoLabel:SetText(Translate.Informations)
	self.InfoLabel:SizeToContents()

	self.InfoLabel1 = vgui.Create("DLabel", self.FunctionPanel)
	self.InfoLabel1:SetPos(15, 320)
	self.InfoLabel1:SetFont("PS2_Normal")
	self.InfoLabel1:SetText(Translate.FirstInfo.." 75.")
	self.InfoLabel1:SizeToContents()

	self.InfoLabel2 = vgui.Create("DLabel", self.FunctionPanel)
	self.InfoLabel2:SetPos(15, 340)
	self.InfoLabel2:SetFont("PS2_Normal")
	self.InfoLabel2:SetText(Translate.SecondInfo)
	self.InfoLabel2:SizeToContents()

	self.InfoLabel3 = vgui.Create("DLabel", self.FunctionPanel)
	self.InfoLabel3:SetPos(15, 380)
	self.InfoLabel3:SetFont("PS2_Normal")
	self.InfoLabel3:SetText(Translate.ThirdInfo)
	self.InfoLabel3:SizeToContents()

	self.InfoLabel4 = vgui.Create("DLabel", self.FunctionPanel)
	self.InfoLabel4:SetPos(15, 440)
	self.InfoLabel4:SetFont("PS2_Normal")
	self.InfoLabel4:SetText(Translate.FourthInfo)
	self.InfoLabel4:SizeToContents()

	self.WinnerPanel = vgui.Create("DPanel", self)
	self.WinnerPanel:Dock(RIGHT)
	self.WinnerPanel:DockMargin(15, 10, 10, 10)
	self.WinnerPanel:SetWide(375)
	Derma_Hook(self.WinnerPanel, "Paint", "Paint", "InnerPanel")

	self.WinnerLabel = vgui.Create("DLabel", self.WinnerPanel)
	self.WinnerLabel:SetPos(15, 10)
	self.WinnerLabel:SetFont("PS2_MediumLarge")
	self.WinnerLabel:SetText(Translate.LastWinners)
	self.WinnerLabel:SizeToContents()
	
	self:UpdatePSL()

	Pointshop2.PSL = self
end

function PSLottery:UpdatePSL()
	self:SetSkin(Pointshop2.Config.DermaSkin)
	
	if IsValid(self.ThreeLabel) then self.ThreeLabel:Remove() end
	self.ThreeLabel = vgui.Create("DLabel", self.FunctionPanel)
	self.ThreeLabel:SetPos(15, 15)
	self.ThreeLabel:SetFont("PS2_Normal")
	self.ThreeLabel:SetText((PSLottery.MaxTickets - LocalPlayer():GetNWInt("TicketsBought")).." "..Translate.AvalibleTickets)
	self.ThreeLabel:SizeToContents()
	
	local roundsleftmsg = Translate.AlreadyPrize
	if PSLottery.RoundsLeft == 1 then
		roundsleftmsg = Translate.MsgEndRound
	elseif PSLottery.RoundsLeft == 2 then
		roundsleftmsg = Translate.MsgNextRound
	elseif PSLottery.RoundsLeft > 2 then
		roundsleftmsg = Translate.MsgNextRound.." "..PSLottery.RoundsLeft.." rounds."
	end
	
	if IsValid(self.ThreeLabel3) then self.ThreeLabel3:Remove() end
	self.ThreeLabel3 = vgui.Create("DLabel", self.FunctionPanel)
	self.ThreeLabel3:SetPos(15, 120)
	self.ThreeLabel3:SetFont("PS2_Normal")
	self.ThreeLabel3:SetText(roundsleftmsg)
	self.ThreeLabel3:SizeToContents()
	
	if IsValid(self.ThreeLabel4) then self.ThreeLabel4:Remove() end
	self.ThreeLabel4 = vgui.Create("DLabel", self.FunctionPanel)
	self.ThreeLabel4:SetPos(15, 140)
	self.ThreeLabel4:SetFont("PS2_Normal")
	self.ThreeLabel4:SetText(Translate.MsgAward.." "..PSLottery.Jackpot.." points.")
	self.ThreeLabel4:SizeToContents()
	
	if IsValid(self.StaticsLabel1) then self.StaticsLabel1:Remove() end
	self.StaticsLabel1 = vgui.Create("DLabel", self.FunctionPanel)
	self.StaticsLabel1:SetPos(15, 210)
	self.StaticsLabel1:SetFont("PS2_Normal")
	self.StaticsLabel1:SetText(Translate.BuyedTickets.." "..PSLottery.Participants)
	self.StaticsLabel1:SizeToContents()
	
	if IsValid(self.StaticsLabel2) then self.StaticsLabel2:Remove() end
	self.StaticsLabel2 = vgui.Create("DLabel", self.FunctionPanel)
	self.StaticsLabel2:SetPos(15, 230)
	self.StaticsLabel2:SetFont("PS2_Normal")
	self.StaticsLabel2:SetText(Translate.LastNumber.." "..PSLottery.LastNumber)
	self.StaticsLabel2:SizeToContents()
	
	if IsValid(self.StaticsLabel3) then self.StaticsLabel3:Remove() end
	self.StaticsLabel3 = vgui.Create("DLabel", self.FunctionPanel)
	self.StaticsLabel3:SetPos(15, 250)
	self.StaticsLabel3:SetFont("PS2_Normal")
	self.StaticsLabel3:SetText(Translate.BestNumber)
	self.StaticsLabel3:SizeToContents()
	
	local winnertext = ""
	for a = 1, 9 do
		if PSLottery.LastWinners[a] then
			winnertext = winnertext..""..a..". "..PSLottery.LastWinners[a].name.." ganhou "..PSLottery.LastWinners[a].value.." pontos.\nEle apostou no "..PSLottery.LastWinners[a].number.." em "..PSLottery.LastWinners[a].windate.."\n\n"
		end
	end
	
	if IsValid(self.WinnerLabel1) then self.WinnerLabel1:Remove() end
	self.WinnerLabel1 = vgui.Create("DLabel", self.WinnerPanel)
	self.WinnerLabel1:SetPos(15, 40)
	self.WinnerLabel1:SetFont("PS2_Normal")
	self.WinnerLabel1:SetText(winnertext)
	self.WinnerLabel1:SizeToContents()
end

net.Receive( "LotteryInfos", function( len )
	PSLottery.TicketPrice = net.ReadInt(16)
	PSLottery.MaxTickets = net.ReadInt(16)
	PSLottery.RoundsLeft = net.ReadInt(16)
	PSLottery.Jackpot = net.ReadInt(32)
	PSLottery.LastNumber = net.ReadInt(16)
	PSLottery.Participants = net.ReadInt(16)
	PSLottery.LastWinners = net.ReadTable()
end )

net.Receive( "LotteryBuy", function( len )
	PSLottery.Jackpot = net.ReadInt(32)
	PSLottery.Participants = net.ReadInt(16)
end )

net.Receive( "LotteryRoundEnd", function( len )
	PSLottery.RoundsLeft = net.ReadInt(16)
	PSLottery.Jackpot = net.ReadInt(32)
	PSLottery.Participants = net.ReadInt(16)
	if IsValid(Pointshop2.PSL) then
		Pointshop2.PSL:UpdatePSL()
	end
end )

net.Receive( "LotteryDrawing", function( len )
	PSLottery.RoundsLeft = net.ReadInt(16)
	PSLottery.Jackpot = net.ReadInt(32)
	PSLottery.LastNumber = net.ReadInt(16)
	PSLottery.Participants = net.ReadInt(16)
	PSLottery.LastWinners = net.ReadTable()
end )

net.Receive( "LotteryMessage", function( len )
	PSLottery.Message = net.ReadString()
	Derma_Message(PSLottery.Message, "Lottery", "OK")
	if IsValid(Pointshop2.PSL) then
		Pointshop2.PSL:UpdatePSL()
	end
end )

Derma_Hook(PSLottery, "Paint", "Paint", "PointshopInventoryTab")
derma.DefineControl("DPointshopPslPanel", "", PSLottery)

Pointshop2:AddInventoryPanel("Lottery", "achievements/coin.png", "DPointshopPslPanel")