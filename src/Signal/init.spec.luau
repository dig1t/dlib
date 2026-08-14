local Signal = require(script.Parent)

return function()
	describe("Fire", function()
		it("should deliver events in order", function()
			local signal = Signal.new()
			local log = {}

			signal:Connect(function(value: string)
				table.insert(log, value)
			end)

			signal:Fire("a")
			signal:Fire("b")

			expect(#log).to.equal(2)
			expect(log[1]).to.equal("a")
			expect(log[2]).to.equal("b")
		end)
	end)

	describe("Reentrant Fire", function()
		it("should not redeliver the in-flight event when a handler fires again", function()
			local signal = Signal.new()
			local firstDeliveries = 0
			local secondDeliveries = 0
			local refired = false

			signal:Connect(function(message: string)
				if message == "first" then
					firstDeliveries += 1

					if not refired then
						refired = true
						signal:Fire("second")
					end
				elseif message == "second" then
					secondDeliveries += 1
				end
			end)

			signal:Fire("first")

			expect(firstDeliveries).to.equal(1)
			expect(secondDeliveries).to.equal(1)
		end)

		it("should terminate when a handler fires unencodable arguments", function()
			-- Regression: Instance args defeat the JSON buffer count and take
			-- the direct path, which used to reflush and redeliver the
			-- original event forever (C stack overflow)
			local signal = Signal.new()
			local calls = 0

			signal:Connect(function(value)
				calls += 1

				if calls > 50 then
					error("runaway recursion")
				end

				if value ~= nil then
					signal:Fire(nil, workspace)
				end
			end)

			signal:Fire({ recordId = "abc" }, workspace)

			expect(calls).to.equal(2)
		end)
	end)
end
