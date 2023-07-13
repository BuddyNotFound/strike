Vehicle = nil
Pilot = nil

Citizen.CreateThread(function()

	while true do
		while not DoesEntityExist(PlayerPedId() or 0) do
			Citizen.Wait(100)
		end

		if InZone() then
			local ped = PlayerPedId()
			Strike(GetEntityCoords(ped), ped)
		end

		Citizen.Wait(15000)
	end
end)

function Strike(coords, ped)
	local model = Config.Vehicle.Model
	LoadModel(model)

	local pilotModel = Config.Vehicle.Pilot
	LoadModel(pilotModel)
	
	local startTime = GetGameTimer()
	local lastUpdate = startTime

	local rad = GetRandomFloatInRange(-3.14, 3.14)
	local direction = vector3(math.cos(rad), math.sin(rad), 0.0)
	local vehicleCoords = coords + vector3(-direction.x * Config.Vehicle.Range, -direction.y * Config.Vehicle.Range, Config.Vehicle.Height)
	local heading = rad * 57.2958 - 90

	Vehicle = CreateVehicle(model, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, heading, false, true)
	Pilot = CreatePed(4, pilotModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, heading, false, true)
	
	SetPedIntoVehicle(Pilot, Vehicle, -1)

	ControlLandingGear(Vehicle, 3)
	SetVehicleEngineOn(Vehicle, true, true, false)
	SetEntityVelocity(Vehicle, direction.x * Config.Vehicle.Speed, direction.y * Config.Vehicle.Speed, 0.0)

	while DoesEntityExist(Vehicle) do
		if not NetworkHasControlOfEntity(Vehicle) then
			NetworkRequestControlOfEntity(Vehicle)
			Citizen.Wait(50)
		end
		
		local delta = (GetGameTimer() - lastUpdate) / 1000.0
		lastUpdate = GetGameTimer()
		
		local coords = coords
		local vehicle = 0
		if ped then
			if not InZone() then
				break
			end

			coords = GetEntityCoords(ped)

			if IsPedInAnyHeli(ped) or IsPedInAnyPlane(ped) then
				vehicle = GetVehiclePedIsIn(ped)
			end
		else
			ped = 0
		end

		TaskPlaneMission(Pilot, Vehicle, vehicle, ped, coords.x, coords.y, coords.z, 6, 0, 0, heading, 2000.0, 400.0)
		

		Citizen.Wait(1000)
	end

	Citizen.Wait(5000)

	if DoesEntityExist(Pilot) then
		DeleteEntity(Pilot)
		Pilot = 0
	end
	
	if DoesEntityExist(Vehicle) then
		DeleteEntity(Vehicle)
		Vehicle = 0
	end
end

function InZone()
	for _, zone in ipairs(Config.Zones) do
		local zone = Config.Zones[_].Coords
		local _coords = GetEntityCoords(PlayerPedId())
		local dist = #(_coords - zone)
		if dist < Config.Zones[_].size then 
			return true 
		end
	end
	return false
end


function LoadModel(model)
	while not HasModelLoaded(model) do
		RequestModel(model)
		Citizen.Wait(25)
	end
end
