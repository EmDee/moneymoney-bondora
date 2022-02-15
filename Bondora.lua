WebBanking {
  version = 1.3,
  url = "https://www.bondora.com",
  description = "Bondora Account",
  services = { "Bondora Account" }
}

-- State
local connection = Connection()
local html

-- Constants
local currency = "EUR"
local locale = "en"
local baseUrl = "https://www.bondora.com/" .. locale

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Bondora Account"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  local url = baseUrl .. "/login"
  MM.printStatus("Login: " .. url)

  -- Fetch login page
  connection.language = "en-US"
  html = HTML(connection:get(url))

  html:xpath("//input[@name='Email']"):attr("value", username)
  html:xpath("//input[@name='Password']"):attr("value", password)

  connection:request(html:xpath("//form[contains(@action, 'login')]//button[@type='submit']"):click())

  if string.match(connection:getBaseURL(), 'login') then
    MM.printStatus("Login Failed")
    return LoginFailed
  end
end

function ListAccounts (knownAccounts)
  -- Parse account info
  local goandgrow = {
    name = "Go&Grow",
    accountNumber = "Go&Grow",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }
  local wallet = {
    name = "Wallet",
    accountNumber = "Wallet",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }


  return {goandgrow, wallet}
end

function AccountSummary ()
  local headers = {accept = "application/json"}
  local content = connection:request(
    "GET",
    baseUrl .. "/dashboard/overviewnumbers/",
    "",
    "application/json",
    headers
  )
  return JSON(content):dictionary()
end

function RefreshAccount (account, since)
  local s = {}
  
  print("Refresh2")
  print(account.accountNumber)

  summary = AccountSummary()

  local value = summary.Stats[1].ValueTooltip
  local profit = summary.Stats[2].ValueTooltip
  local wallet = summary.Stats[3].ValueTooltip
  local numberRegex = "[^%d|.|-]"

  print("Profit (raw): " .. profit)
  print("Value (raw): " .. value)

  profit = string.gsub(profit, numberRegex, "")
  value = string.gsub(value, numberRegex, "")
  wallet = string.gsub(wallet, numberRegex, "")

  print("Value (extracted number): " .. value)
  print("Wallet (extracted number):" .. wallet)
  print("Profit (extracted number): " .. profit)

  print("Value (in Euros): " .. tonumber(value))
  print("Wallet (in Euros):" .. tonumber(wallet))
  print("Profit (in Euros): " .. tonumber(profit))

  local currentPrice = (tonumber(value) - tonumber(wallet))
  local purchasePrice = (currentPrice - tonumber(profit))
  


  print("Purchase price: " .. purchasePrice)
  
  local security = {
    name = "Account",
    quantity = 1,
    currency = nil,
  }

  if account.accountNumber == "Go&Grow" then
    
    security.price = currentPrice
    security.purchasePrice = purchasePrice
    
  elseif account.accountNumber =="Wallet" then
    security.price = wallet
    security.purchasePrice = wallet
  else
    error("invalid account")
  end 

  --[[
  local security = {
    name = "Account",
    price = currentPrice,
    quantity = 1,
    purchasePrice = purchasePrice,
    currency = nil,
  }
  --]]


  table.insert(s, security)

  return {securities = s}
end


function EndSession ()
  local url = baseUrl .. "/authorize/logout/"
  MM.printStatus("Logout: " .. url)
  connection:get(url)
  return nil
end
