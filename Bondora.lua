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
local baseUrl = "https://www.bondora.com"
local baseUrlLocale = "https://www.bondora.com/" .. locale

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Bondora Account"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  local url = baseUrlLocale .. "/login"
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
  local account = {
    name = "Bondora Summary",
    accountNumber = "Bondora Summary",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function AccountSummary ()
  local headers = {accept = "application/json"}
  local content = connection:request(
    "GET",
    baseUrl .. "/api/GoGrowDashboard/GoGrowDashboardAccountInfo",
    "",
    "application/json",
    headers
  )
  return JSON(content):dictionary()
end

function RefreshAccount (account, since)
  local s = {}

  summary = AccountSummary()

  local value = summary.CurrentAccountValue
  local profit = summary.GainedTotal
  local numberRegex = "[^%d|.|-]"

  print("Profit (raw): " .. profit)
  print("Value (raw): " .. value)

  profit = string.gsub(profit, numberRegex, "")
  value = string.gsub(value, numberRegex, "")

  print("Profit (extracted number): " .. profit)
  print("Value (extracted number): " .. value)

  print("Profit (in Euros): " .. tonumber(profit))
  print("Value (in Euros): " .. tonumber(value))

  local purchasePrice = (tonumber(value) - tonumber(profit))

  print("Purchase price: " .. purchasePrice)

  local security = {
    name = "Account",
    price = tonumber(value),
    quantity = 1,
    purchasePrice = purchasePrice,
    currency = nil,
  }

  table.insert(s, security)

  return {securities = s}
end

function EndSession ()
  local url = baseUrlLocale .. "/authorize/logout/"
  MM.printStatus("Logout: " .. url)
  connection:get(url)
  return nil
end

-- SIGNATURE: MCwCFQCTUbXmmBzwn+HcaBSuZ5cJgbiBuwITBD7d01qCIvvJxquVlzDa4JMDFA==
