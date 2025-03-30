--[[ Bezier
    Cubic Bezier curve implementation for smooth path interpolation.
    Provides utilities for curve generation and point sampling.
    @author @Daystopia
    @version 1.0.0
    @date 2025-01-14
]]
local Bezier = {}
Bezier.__index = Bezier

local TweenService = game:GetService("TweenService")

-- Types
export type BezierPoint = {
	Type: "StaticPoint" | "BasePartPoint",
	Point: Vector3 | BasePart
}

export type BezierConfig = {
	LengthIterations: number?,
	Points: {BezierPoint}?
}

-- Constants
local LENGTH_ITERATIONS = 1000

local factorialCache = {}

-- Utilities
local function factorial(n: number): number
	if factorialCache[n] then
		return factorialCache[n]
	end

	local result = 1
	for i = 2, n do
		result *= i
	end
	factorialCache[n] = result
	return result
end

local function calculateBernsteinPolynomial(n: number, i: number, t: number): number
	local nFact = factorial(n)
	local iFact = factorial(i)
	local nMinusIFact = factorial(n - i)
	return (nFact / (iFact * nMinusIFact)) * t^i * (1 - t)^(n - i)
end

local function setupConnections(self: any, point: BezierPoint, basepart: BasePart)
	if not self._connections[basepart] then
		self._connections[basepart] = {}
	end

	local connections = self._connections[basepart]

	table.insert(connections, basepart.Changed:Connect(function(prop)
		if prop == "Position" then
			self:UpdateLength()
		end
	end))

	table.insert(connections, basepart.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			local index = table.find(self.Points, point)
			if index then
				table.remove(self.Points, index)
			end
			for _, connection in connections do
				connection:Disconnect() 
			end
			self._connections[basepart] = nil
		end
	end))
end

-- Constructor
function Bezier.new(...: Vector3 | BasePart)
	local self = setmetatable({
		Points = {},
		LengthIterations = LENGTH_ITERATIONS,
		LengthIndeces = {},
		Length = 0,
		_connections = {}
	}, Bezier)

	for _, point in {...} do
		if typeof(point) == "Vector3" or (typeof(point) == "Instance" and point:IsA("BasePart")) then
			self:AddBezierPoint(point)
		else
			error("Only accepts Vector3s and BaseParts as inputs")
		end
	end

	return self
end

-- Methods
function Bezier:AddBezierPoint(point: Vector3 | BasePart, index: number?)
	if not (typeof(point) == "Vector3" or (typeof(point) == "Instance" and point:IsA("BasePart"))) then
		error("Only accepts a Vector3 or BasePart as the first argument")
	end

	local pointType = typeof(point) == "Vector3" and "StaticPoint" or "BasePartPoint"
	local newPoint: BezierPoint = {
		Type = pointType,
		Point = point
	}

	if pointType == "BasePartPoint" then
		setupConnections(self, newPoint, point)
	end

	if type(index) == "number" then
		table.insert(self.Points, index, newPoint)
	else
		table.insert(self.Points, newPoint)
	end

	self:UpdateLength()
end

function Bezier:GetPoint(index: number): Vector3?
	local point = self.Points[index]
	if not point then
		error("Did not find a BezierPoint at index " .. tostring(index))
	end

	return point.Type == "StaticPoint" and point.Point or point.Point.Position
end

function Bezier:GetAllPoints(): {Vector3}
	local points = table.create(#self.Points)
	for i = 1, #self.Points do
		points[i] = self:GetPoint(i)
	end
	return points
end

function Bezier:ChangeBezierPoint(index: number, point: Vector3 | BasePart)
	if type(index) ~= "number" then
		error("Only accepts a number index as the first argument")
	end

	if not (typeof(point) == "Vector3" or (typeof(point) == "Instance" and point:IsA("BasePart"))) then
		error("Only accepts a Vector3 or BasePart as the second argument")
	end

	local bezierPoint = self.Points[index]
	if not bezierPoint then
		error("Did not find BezierPoint at index " .. tostring(index))
	end

	bezierPoint.Type = typeof(point) == "Vector3" and "StaticPoint" or "BasePartPoint"
	bezierPoint.Point = point
	self:UpdateLength()
end

function Bezier:RemoveBezierPoint(index: number)
	local point = self.Points[index]
	if point then
		if point.Type == "BasePartPoint" then
			for _, connection in self._connections[point.Point] do
				connection:Disconnect()
			end
			self._connections[point.Point] = nil
		end
		table.remove(self.Points, index)
		self:UpdateLength()
	end
end

function Bezier:UpdateLength()
	if #self.Points < 2 then
		self.Length = 0
		table.clear(self.LengthIndeces)
		return
	end

	local length = 0
	local sums = table.create(self.LengthIterations)
	local iterationStep = 1 / (self.LengthIterations - 1)

	for i = 1, self.LengthIterations do
		local t = (i - 1) * iterationStep
		local derivative = self:CalculateDerivativeAt(t)
		length += derivative.Magnitude * iterationStep
		sums[i] = {t, length, derivative}
	end

	self.Length = length
	self.LengthIndeces = sums
end

function Bezier:CalculatePositionAt(t: number): Vector3
	if type(t) ~= "number" then
		error("Only accepts a number")
	end

	if #self.Points == 0 then
		error("Requires at least 1 BezierPoint")
	end

	local points = self:GetAllPoints()
	local n = #points - 1
	local position = Vector3.new()

	for i = 0, n do
		local point = points[i + 1]
		local bernstein = calculateBernsteinPolynomial(n, i, t)
		position += bernstein * point
	end

	return position
end

function Bezier:CalculateDerivativeAt(t: number): Vector3
	if type(t) ~= "number" then
		error("Only accepts a number")
	end

	if #self.Points < 2 then
		error("Requires at least 2 BezierPoints")
	end

	local points = self:GetAllPoints()
	local n = #points - 1
	local derivative = Vector3.new()

	for i = 0, n - 1 do
		local q = n * (points[i + 2] - points[i + 1])
		local bernstein = calculateBernsteinPolynomial(n - 1, i, t)
		derivative += bernstein * q
	end

	return derivative
end

function Bezier:CalculatePositionRelativeToLength(t: number): Vector3
	if type(t) ~= "number" then
		error("Only accepts a number")
	end

	if #self.Points == 0 then
		error("Requires at least 1 BezierPoint")
	end

	if #self.Points == 1 then
		return self:CalculatePositionAt(0)
	end

	local targetLength = self.Length * t
	local nearestParameter

	local low, high = 1, #self.LengthIndeces
	while low <= high do
		local mid = math.floor((low + high) / 2)
		local orderedPair = self.LengthIndeces[mid]

		if targetLength - orderedPair[2] <= 0 then
			nearestParameter = orderedPair
			high = mid - 1
		else
			low = mid + 1
		end
	end

	if not nearestParameter then
		nearestParameter = self.LengthIndeces[#self.LengthIndeces]
	end

	local p0 = self:CalculatePositionAt(nearestParameter[1])
	local p1 = self:CalculatePositionAt(math.min(nearestParameter[1] + 1/self.LengthIterations, 1))
	local percentError = (nearestParameter[2] - targetLength) / (p1 - p0).Magnitude

	return p0:Lerp(p1, 1 - percentError)
end

function Bezier:CreateVector3Tween(object: Instance | {[any]: any}, propertyTable: {string}, tweenInfo: TweenInfo, relativeToLength: boolean?): Tween
	if #self.Points == 0 then
		error("Requires at least 1 BezierPoint")
	end

	if typeof(object) ~= "Instance" and typeof(object) ~= "table" then
		error("Requires an Instance or a table as the first argument")
	end

	if not (typeof(tweenInfo) == "TweenInfo") then
		error("Requires a TweenInfo object as the third argument")
	end

	for _, propertyName in propertyTable do
		local propValue = object[propertyName]
		if propValue ~= nil and typeof(propValue) ~= "Vector3" then
			error("Requires valid Vector3 properties")
		end
	end

	local numValue = Instance.new("NumberValue")
	local tween = TweenService:Create(numValue, tweenInfo, {Value = 1})
	local calculatePosition = relativeToLength and self.CalculatePositionRelativeToLength or self.CalculatePositionAt
	local connection

	tween.Changed:Connect(function(prop)
		if prop == "PlaybackState" then
			if tween.PlaybackState == Enum.PlaybackState.Playing then
				connection = numValue.Changed:Connect(function(t)
					local position = calculatePosition(self, t)
					for _, propName in propertyTable do
						object[propName] = position
					end
				end)
			else
				if connection then
					connection:Disconnect()
					connection = nil
				end
			end
		end
	end)

	return tween
end

function Bezier:CreateCFrameTween(object: Instance | {[any]: any}, propertyTable: {string}, tweenInfo: TweenInfo, relativeToLength: boolean?): Tween
	if #self.Points <= 1 then
		error("Bezier:CreateCFrameTween() requires at least 2 BezierPoints")
	end

	if typeof(object) ~= "Instance" and typeof(object) ~= "table" then
		error("Requires an Instance or a table as the first argument")
	end

	if not (typeof(tweenInfo) == "TweenInfo") then
		error("Requires a TweenInfo object as the third argument")
	end

	for _, propertyName in propertyTable do
		local propValue = object[propertyName]
		if propValue ~= nil and typeof(propValue) ~= "CFrame" then
			error("Requires valid CFrame properties")
		end
	end

	local numValue = Instance.new("NumberValue")
	local tween = TweenService:Create(numValue, tweenInfo, {Value = 1})
	local calculatePosition = relativeToLength and self.CalculatePositionRelativeToLength or self.CalculatePositionAt
	local calculateDerivative = relativeToLength and self.CalculateDerivativeRelativeToLength or self.CalculateDerivativeAt
	local connection

	tween.Changed:Connect(function(prop)
		if prop == "PlaybackState" then
			if tween.PlaybackState == Enum.PlaybackState.Playing then
				connection = numValue.Changed:Connect(function(t)
					local position = calculatePosition(self, t)
					local derivative = calculateDerivative(self, t)
					local cf = CFrame.new(position, position + derivative)
					for _, propName in propertyTable do
						object[propName] = cf
					end
				end)
			else
				if connection then
					connection:Disconnect()
					connection = nil
				end
			end
		end
	end)

	return tween
end

return Bezier