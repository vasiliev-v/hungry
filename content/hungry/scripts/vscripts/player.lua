CustomPlayerResource = CustomPlayerResource or {}
CustomPlayerResource.data = CustomPlayerResource.data or {}

function StableSort(A)
  local itemCount=#A-1
  --print(itemCount)

 for i = 1, itemCount do
    	for i = 1, itemCount do
      		if A[i].rating < A[i + 1].rating then
        		A[i], A[i + 1] = A[i + 1], A[i]
      		elseif  A[i].rating == A[i + 1].rating and A[i].previousPlace > A[i + 1].previousPlace then
        		A[i], A[i + 1] = A[i + 1], A[i]
      		end
    	end
  	end
end

function CustomPlayerResource:InitPlayer(playerID)

	if not self.data[playerID] then
	 	CustomPlayerResource.counter = (CustomPlayerResource.counter or 0) + 1
		self.data[playerID] = {}
		self.data[playerID].place = CustomPlayerResource.counter
		self.data[playerID].team = DOTA_TEAM_GOODGUYS 
		GameRules.Bonus[playerID] = 0

		GameRules.PoolTable = {}
		GameRules.PoolTable[0] = {} -- валюта
		GameRules.PoolTable[1] = {} -- эффекты и петы
		GameRules.PoolTable[2] = {} -- шанс тролля
		GameRules.PoolTable[3] = {} -- бонус рейт
		GameRules.PoolTable[4] = {} -- сундуки
		GameRules.PoolTable[5] = {} -- инфа перса
		GameRules.PoolTable[6] = {} -- ежедневки 
		GameRules.PoolTable[7] = {} -- опыт батл пасса 
		GameRules.PoolTable[8] = {} -- статистика за эльфа 
		GameRules.PoolTable[9] = {} -- статистика за тролля
		GameRules.PoolTable[10] = {} -- батлпасс
		GameRules.PoolTable[0][0] = {}
		GameRules.PoolTable[1][0] = {}
		GameRules.PoolTable[2][0] = {}
		GameRules.PoolTable[3][0] = {}
		GameRules.PoolTable[4][0] = {}
		GameRules.PoolTable[4][0][0] = {}
		GameRules.PoolTable[5][0] = {}
		GameRules.PoolTable[6][0] = {}
		GameRules.PoolTable[7][0] = {}
		GameRules.PoolTable[7][0][0] = {}
		GameRules.PoolTable[8][0] = {} 
		GameRules.PoolTable[9][0] = {} 
		GameRules.PoolTable[10][0] = {} 
		GameRules.PoolTable[10][0][0] = {} 
		CustomNetTables:SetTableValue("Shop", tostring(playerID), GameRules.PoolTable)

	end

end

