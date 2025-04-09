--[[ Promise
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-09
]]

local Promise = {}
Promise.__index = Promise

export type PromiseStatus = "Pending" | "Fulfilled" | "Rejected"

export type PromiseExecutor = (
    resolve: (value: any) -> (),
    reject: (reason: any) -> ()
) -> ()

export type PromiseObject = {
    Status: PromiseStatus,
    Value: any,
    Reason: any,

    andThen: (self: PromiseObject, onFulfilled: ((value: any) -> any)?, onRejected: ((reason: any) -> any)?) -> PromiseObject,
    onError: (self: PromiseObject, onRejected: (reason: any) -> any) -> PromiseObject,
    onFinally: (self: PromiseObject, onFinally: () -> ()) -> PromiseObject,
    await: (self: PromiseObject) -> (boolean, ...any),

    _state: "Pending" | "Fulfilled" | "Rejected",
    _value: any,
    _reason: any,
    _thenQueue: {any},
    _catchQueue: {any},
    _finallyQueue: {any},
    _linkedPromises: {PromiseObject}
}

Promise.Status = {
    Pending = "Pending",
    Fulfilled = "Fulfilled",
    Rejected = "Rejected"
}

function Promise.new(executor: PromiseExecutor): PromiseObject
    local self = setmetatable({
        _state = Promise.Status.Pending,
        _value = nil,
        _reason = nil,
        _thenQueue = {},
        _catchQueue = {},
        _finallyQueue = {},
        _linkedPromises = {}
    }, Promise)

    self.Status = Promise.Status.Pending
    self.Value = nil
    self.Reason = nil

    local function reject(reason)
        if self._state ~= Promise.Status.Pending then return end

        self._state = Promise.Status.Rejected
        self._reason = reason
        self.Status = Promise.Status.Rejected
        self.Reason = reason

        for _, callback in ipairs(self._catchQueue) do
            task.spawn(callback, reason)
        end

        for _, callback in ipairs(self._finallyQueue) do
            task.spawn(callback)
        end

        for _, linkedPromise in ipairs(self._linkedPromises) do
            if linkedPromise._state == Promise.Status.Pending then
                linkedPromise._state = Promise.Status.Rejected
                linkedPromise._reason = reason
                linkedPromise.Status = Promise.Status.Rejected
                linkedPromise.Reason = reason

                for _, callback in ipairs(linkedPromise._catchQueue) do
                    task.spawn(callback, reason)
                end

                for _, callback in ipairs(linkedPromise._finallyQueue) do
                    task.spawn(callback)
                end
            end
        end

        table.clear(self._thenQueue)
        table.clear(self._catchQueue)
        table.clear(self._finallyQueue)
    end

    local function resolve(value)
        if self._state ~= Promise.Status.Pending then return end

        if type(value) == "table" and value.andThen and type(value.andThen) == "function" then
            value:andThen(
                function(resolvedValue)
                    resolve(resolvedValue)
                end,
                function(rejectedReason)
                    reject(rejectedReason)
                end
            )
            return
        end

        self._state = Promise.Status.Fulfilled
        self._value = value
        self.Status = Promise.Status.Fulfilled
        self.Value = value

        for _, callback in ipairs(self._thenQueue) do
            task.spawn(callback, value)
        end

        for _, callback in ipairs(self._finallyQueue) do
            task.spawn(callback)
        end

        for _, linkedPromise in ipairs(self._linkedPromises) do
            if linkedPromise._state == Promise.Status.Pending then
                linkedPromise._state = Promise.Status.Fulfilled
                linkedPromise._value = value
                linkedPromise.Status = Promise.Status.Fulfilled
                linkedPromise.Value = value

                for _, callback in ipairs(linkedPromise._thenQueue) do
                    task.spawn(callback, value)
                end

                for _, callback in ipairs(linkedPromise._finallyQueue) do
                    task.spawn(callback)
                end
            end
        end

        table.clear(self._thenQueue)
        table.clear(self._catchQueue)
        table.clear(self._finallyQueue)
    end

    task.spawn(function()
        local success, result = pcall(executor, resolve, reject)
        if not success and self._state == Promise.Status.Pending then
            reject(result)
        end
    end)

    return self
end

function Promise.resolve(value: any): PromiseObject
    return Promise.new(function(resolve)
        resolve(value)
    end)
end

function Promise.reject(reason: any): PromiseObject
    return Promise.new(function(_, reject)
        reject(reason)
    end)
end

function Promise.delay(seconds: number, value: any?): PromiseObject
    return Promise.new(function(resolve)
        task.delay(seconds, function()
            resolve(value)
        end)
    end)
end

function Promise.timeout(seconds: number, reason: any?): PromiseObject
    return Promise.new(function(_, reject)
        task.delay(seconds, function()
            reject(reason or "Promise timed out")
        end)
    end)
end

function Promise:withTimeout(seconds, reason)
    return Promise.race({
        self,
        Promise.timeout(seconds, reason or "Promise timed out")
    })
end

function Promise.all(promises: {PromiseObject}): PromiseObject
    if #promises == 0 then
        return Promise.resolve({})
    end

    return Promise.new(function(resolve, reject)
        local results = table.create(#promises)
        local remainingCount = #promises

        for i, promise in ipairs(promises) do
            promise:andThen(
                function(value)
                    results[i] = value
                    remainingCount -= 1

                    if remainingCount == 0 then
                        resolve(results)
                    end
                end,
                function(reason)
                    reject(reason)
                end
            )
        end
    end)
end

function Promise.allSettled(promises: {PromiseObject}): PromiseObject
    if #promises == 0 then
        return Promise.resolve({})
    end

    return Promise.new(function(resolve)
        local results = table.create(#promises)
        local remainingCount = #promises

        for i, promise in ipairs(promises) do
            promise:andThen(
                function(value)
                    results[i] = {
                        status = "fulfilled",
                        value = value
                    }
                    remainingCount -= 1

                    if remainingCount == 0 then
                        resolve(results)
                    end
                end,
                function(reason)
                    results[i] = {
                        status = "rejected",
                        reason = reason
                    }
                    remainingCount -= 1

                    if remainingCount == 0 then
                        resolve(results)
                    end
                end
            )
        end
    end)
end

function Promise.race(promises: {PromiseObject}): PromiseObject
    return Promise.new(function(resolve, reject)
        for _, promise in ipairs(promises) do
            promise:andThen(resolve, reject)
        end
    end)
end

function Promise.any(promises: {PromiseObject}): PromiseObject
    if #promises == 0 then
        return Promise.reject("No promises provided to Promise.any")
    end

    return Promise.new(function(resolve, reject)
        local errors = table.create(#promises)
        local remainingCount = #promises

        for i, promise in ipairs(promises) do
            promise:andThen(
                function(value)
                    resolve(value)
                end,
                function(reason)
                    errors[i] = reason
                    remainingCount -= 1

                    if remainingCount == 0 then
                        reject({
                            name = "AggregateError",
                            message = "All promises were rejected",
                            errors = errors
                        })
                    end
                end
            )
        end
    end)
end

function Promise.some(promises: {PromiseObject}, count: number): PromiseObject
    if #promises == 0 then
        return Promise.reject("No promises provided to Promise.some")
    end

    if count <= 0 then
        return Promise.reject("Count must be greater than 0")
    end

    if count > #promises then
        count = #promises
    end

    return Promise.new(function(resolve, reject)
        local results = table.create(#promises)
        local fulfilled = 0
        local rejected = 0
        local errors = table.create(#promises)

        for i, promise in ipairs(promises) do
            promise:andThen(
                function(value)
                    results[i] = value
                    fulfilled += 1

                    if fulfilled >= count then
                        local fulfilledResults = {}
                        for j, result in ipairs(results) do
                            if result ~= nil then
                                table.insert(fulfilledResults, result)
                                if #fulfilledResults >= count then
                                    break
                                end
                            end
                        end
                        resolve(fulfilledResults)
                    end
                end,
                function(reason)
                    errors[i] = reason
                    rejected += 1

                    if rejected > (#promises - count) then
                        reject({
                            name = "AggregateError",
                            message = "Not enough promises were fulfilled",
                            errors = errors
                        })
                    end
                end
            )
        end
    end)
end

function Promise.withResolvers()
    local resolve, reject
    local promise = Promise.new(function(res, rej)
        resolve = res
        reject = rej
    end)

    return {
        promise = promise,
        resolve = resolve,
        reject = reject
    }
end

function Promise:andThen(onFulfilled, onRejected)
    local nextPromise = Promise.new(function() end)
    table.insert(self._linkedPromises, nextPromise)

    if self._state == Promise.Status.Fulfilled then
        if type(onFulfilled) == "function" then
            task.spawn(function()
                local success, result = pcall(onFulfilled, self._value)
                if success then
                    if type(result) == "table" and result.andThen and type(result.andThen) == "function" then
                        result:andThen(
                            function(value)
                                nextPromise._state = Promise.Status.Fulfilled
                                nextPromise._value = value
                                nextPromise.Status = Promise.Status.Fulfilled
                                nextPromise.Value = value

                                for _, callback in ipairs(nextPromise._thenQueue) do
                                    task.spawn(callback, value)
                                end
                                table.clear(nextPromise._thenQueue)
                            end,
                            function(reason)
                                nextPromise._state = Promise.Status.Rejected
                                nextPromise._reason = reason
                                nextPromise.Status = Promise.Status.Rejected
                                nextPromise.Reason = reason

                                for _, callback in ipairs(nextPromise._catchQueue) do
                                    task.spawn(callback, reason)
                                end
                                table.clear(nextPromise._catchQueue)
                            end
                        )
                    else
                        nextPromise._state = Promise.Status.Fulfilled
                        nextPromise._value = result
                        nextPromise.Status = Promise.Status.Fulfilled
                        nextPromise.Value = result

                        for _, callback in ipairs(nextPromise._thenQueue) do
                            task.spawn(callback, result)
                        end
                        table.clear(nextPromise._thenQueue)
                    end
                else
                    nextPromise._state = Promise.Status.Rejected
                    nextPromise._reason = result
                    nextPromise.Status = Promise.Status.Rejected
                    nextPromise.Reason = result

                    for _, callback in ipairs(nextPromise._catchQueue) do
                        task.spawn(callback, result)
                    end
                    table.clear(nextPromise._catchQueue)
                end
            end)
        else
            nextPromise._state = Promise.Status.Fulfilled
            nextPromise._value = self._value
            nextPromise.Status = Promise.Status.Fulfilled
            nextPromise.Value = self._value
        end
    elseif self._state == Promise.Status.Rejected then
        if type(onRejected) == "function" then
            task.spawn(function()
                local success, result = pcall(onRejected, self._reason)
                if success then
                    if type(result) == "table" and result.andThen and type(result.andThen) == "function" then
                        result:andThen(
                            function(value)
                                nextPromise._state = Promise.Status.Fulfilled
                                nextPromise._value = value
                                nextPromise.Status = Promise.Status.Fulfilled
                                nextPromise.Value = value

                                for _, callback in ipairs(nextPromise._thenQueue) do
                                    task.spawn(callback, value)
                                end
                                table.clear(nextPromise._thenQueue)
                            end,
                            function(reason)
                                nextPromise._state = Promise.Status.Rejected
                                nextPromise._reason = reason
                                nextPromise.Status = Promise.Status.Rejected
                                nextPromise.Reason = reason

                                for _, callback in ipairs(nextPromise._catchQueue) do
                                    task.spawn(callback, reason)
                                end
                                table.clear(nextPromise._catchQueue)
                            end
                        )
                    else
                        nextPromise._state = Promise.Status.Fulfilled
                        nextPromise._value = result
                        nextPromise.Status = Promise.Status.Fulfilled
                        nextPromise.Value = result

                        for _, callback in ipairs(nextPromise._thenQueue) do
                            task.spawn(callback, result)
                        end
                        table.clear(nextPromise._thenQueue)
                    end
                else
                    nextPromise._state = Promise.Status.Rejected
                    nextPromise._reason = result
                    nextPromise.Status = Promise.Status.Rejected
                    nextPromise.Reason = result

                    for _, callback in ipairs(nextPromise._catchQueue) do
                        task.spawn(callback, result)
                    end
                    table.clear(nextPromise._catchQueue)
                end
            end)
        else
            nextPromise._state = Promise.Status.Rejected
            nextPromise._reason = self._reason
            nextPromise.Status = Promise.Status.Rejected
            nextPromise.Reason = self._reason
        end
    else
        if type(onFulfilled) == "function" then
            table.insert(self._thenQueue, function(value)
                local success, result = pcall(onFulfilled, value)
                if success then
                    if type(result) == "table" and result.andThen and type(result.andThen) == "function" then
                        result:andThen(
                            function(chainedValue)
                                nextPromise._state = Promise.Status.Fulfilled
                                nextPromise._value = chainedValue
                                nextPromise.Status = Promise.Status.Fulfilled
                                nextPromise.Value = chainedValue

                                for _, callback in ipairs(nextPromise._thenQueue) do
                                    task.spawn(callback, chainedValue)
                                end
                                table.clear(nextPromise._thenQueue)
                            end,
                            function(reason)
                                nextPromise._state = Promise.Status.Rejected
                                nextPromise._reason = reason
                                nextPromise.Status = Promise.Status.Rejected
                                nextPromise.Reason = reason

                                for _, callback in ipairs(nextPromise._catchQueue) do
                                    task.spawn(callback, reason)
                                end
                                table.clear(nextPromise._catchQueue)
                            end
                        )
                    else
                        nextPromise._state = Promise.Status.Fulfilled
                        nextPromise._value = result
                        nextPromise.Status = Promise.Status.Fulfilled
                        nextPromise.Value = result

                        for _, callback in ipairs(nextPromise._thenQueue) do
                            task.spawn(callback, result)
                        end
                        table.clear(nextPromise._thenQueue)
                    end
                else
                    nextPromise._state = Promise.Status.Rejected
                    nextPromise._reason = result
                    nextPromise.Status = Promise.Status.Rejected
                    nextPromise.Reason = result

                    for _, callback in ipairs(nextPromise._catchQueue) do
                        task.spawn(callback, result)
                    end
                    table.clear(nextPromise._catchQueue)
                end
            end)
        end

        if type(onRejected) == "function" then
            table.insert(self._catchQueue, function(reason)
                local success, result = pcall(onRejected, reason)
                if success then
                    if type(result) == "table" and result.andThen and type(result.andThen) == "function" then
                        result:andThen(
                            function(value)
                                nextPromise._state = Promise.Status.Fulfilled
                                nextPromise._value = value
                                nextPromise.Status = Promise.Status.Fulfilled
                                nextPromise.Value = value

                                for _, callback in ipairs(nextPromise._thenQueue) do
                                    task.spawn(callback, value)
                                end
                                table.clear(nextPromise._thenQueue)
                            end,
                            function(rejectedReason)
                                nextPromise._state = Promise.Status.Rejected
                                nextPromise._reason = rejectedReason
                                nextPromise.Status = Promise.Status.Rejected
                                nextPromise.Reason = rejectedReason

                                for _, callback in ipairs(nextPromise._catchQueue) do
                                    task.spawn(callback, rejectedReason)
                                end
                                table.clear(nextPromise._catchQueue)
                            end
                        )
                    else
                        nextPromise._state = Promise.Status.Fulfilled
                        nextPromise._value = result
                        nextPromise.Status = Promise.Status.Fulfilled
                        nextPromise.Value = result

                        for _, callback in ipairs(nextPromise._thenQueue) do
                            task.spawn(callback, result)
                        end
                        table.clear(nextPromise._thenQueue)
                    end
                else
                    nextPromise._state = Promise.Status.Rejected
                    nextPromise._reason = result
                    nextPromise.Status = Promise.Status.Rejected
                    nextPromise.Reason = result

                    for _, callback in ipairs(nextPromise._catchQueue) do
                        task.spawn(callback, result)
                    end
                    table.clear(nextPromise._catchQueue)
                end
            end)
        end
    end

    return nextPromise
end

function Promise:onError(onRejected)
    return self:andThen(nil, onRejected)
end

Promise.catch = Promise.onError

function Promise:onFinally(onFinally)
    if self._state == Promise.Status.Pending then
        table.insert(self._finallyQueue, onFinally)
    else
        task.spawn(onFinally)
    end

    return self:andThen(
        function(value)
            local success, result = pcall(onFinally)
            if success then
                return value
            else
                return Promise.reject(result)
            end
        end,
        function(reason)
            local success, result = pcall(onFinally)
            if success then
                return Promise.reject(reason)
            else
                return Promise.reject(result)
            end
        end
    )
end

Promise.finally = Promise.onFinally

function Promise:await()
    if self._state == Promise.Status.Fulfilled then
        return true, self._value
    elseif self._state == Promise.Status.Rejected then
        return false, self._reason
    end

    local thread = coroutine.running()

    self:onFinally(function()
        local success, result = coroutine.resume(thread)
        if not success then
            warn("Promise:await error:", result)
        end
    end)

    coroutine.yield()

    if self._state == Promise.Status.Fulfilled then
        return true, self._value
    else
        return false, self._reason
    end
end

function Promise.never()
    return Promise.new(function() end)
end

function Promise.cancellable(executor)
    local cancelled = false
    local onCancel = nil

    local promise = Promise.new(function(resolve, reject)
        local wrappedResolve = function(...)
            if cancelled then return end
            resolve(...)
        end

        local wrappedReject = function(...)
            if cancelled then return end
            reject(...)
        end

        onCancel = executor(wrappedResolve, wrappedReject)
    end)

    function promise:cancel()
        if cancelled then return end
        cancelled = true

        if type(onCancel) == "function" then
            onCancel()
        end
    end

    return promise
end

function Promise.retry(callback, maxAttempts, delayBetweenAttempts)
    maxAttempts = maxAttempts or 3
    delayBetweenAttempts = delayBetweenAttempts or 1

    return Promise.new(function(resolve, reject)
        local function attempt(currentAttempt)
            Promise.new(function(attemptResolve, attemptReject)
                local result = callback(currentAttempt)

                if type(result) == "table" and result.andThen and type(result.andThen) == "function" then
                    result:andThen(attemptResolve, attemptReject)
                else
                    attemptResolve(result)
                end
            end):andThen(
                function(result)
                    resolve(result)
                end,
                function(reason)
                    if currentAttempt >= maxAttempts then
                        reject({
                            reason = reason,
                            attempts = currentAttempt
                        })
                    else
                        task.delay(delayBetweenAttempts, function()
                            attempt(currentAttempt + 1)
                        end)
                    end
                end
            )
        end

        attempt(1)
    end)
end

function Promise.try(callback)
    return Promise.new(function(resolve, reject)
        local success, result = pcall(callback)

        if success then
            if type(result) == "table" and result.andThen and type(result.andThen) == "function" then
                result:andThen(resolve, reject)
            else
                resolve(result)
            end
        else
            reject(result)
        end
    end)
end

function Promise.props(promises)
    local keys = {}
    local promiseArray = {}

    for k, v in pairs(promises) do
        table.insert(keys, k)
        table.insert(promiseArray, v)
    end

    return Promise.all(promiseArray):andThen(function(results)
        local resultTable = {}
        for i, key in ipairs(keys) do
            resultTable[key] = results[i]
        end
        return resultTable
    end)
end

function Promise.promisify(callbackFn)
    return function(...)
        local args = {...}
        return Promise.new(function(resolve, reject)
            table.insert(args, function(err, result)
                if err then
                    reject(err)
                else
                    resolve(result)
                end
            end)

            local success, err = pcall(function()
                callbackFn(unpack(args))
            end)

            if not success then
                reject(err)
            end
        end)
    end
end

function Promise.fromEvent(event, predicate)
    return Promise.new(function(resolve)
        local connection
        connection = event:Connect(function(...)
            local args = {...}
            if not predicate or predicate(unpack(args)) then
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                resolve(args)
            end
        end)
    end)
end

return Promise