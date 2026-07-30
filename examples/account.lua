package.path = "./?.lua;./?/init.lua;" .. package.path
local guard = require("guardrail")

local balance = guard.invariant({ name = "non_negative_balance", check = function(account) return account.balance >= 0 end, message = "account balance cannot be negative" })
local withdraw = guard.contract({
  name = "withdraw", args = { guard.table({ balance = guard.number({ min = 0 }) }), guard.number({ positive = true }) },
  requires = function(account, amount) return account.balance >= amount, "insufficient funds" end,
  returns = guard.number({ min = 0 })
}, function(account, amount) account.balance = account.balance - amount; return account.balance end)

local account = { balance = 100 }
print(guard.with_invariant(balance, account, function() return withdraw(account, 25) end))
