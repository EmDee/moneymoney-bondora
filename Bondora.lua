WebBanking {
  version = 1.1,
  url = "https://www.bondora.com",
  description = "Bondora Account",
  services = { "Bondora Account" }
}

-- State
local connection = Connection()
local html

-- Constants
local currency = "EUR"

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Bondora Account"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  MM.printStatus("Login")

  -- Fetch login page
  connection.language = "de-de"
  html = HTML(connection:get("https://www.bondora.com/de/login"))

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
    "https://www.bondora.com/de/dashboard/overviewnumbers/",
    "",
    "application/json",
    headers
  )
  return JSON(content):dictionary()
end

function RefreshAccount (account, since)
  local s = {}
  summary = AccountSummary()

  local value = summary.Stats[1].ValueTooltip
  local profit = summary.Stats[2].ValueTooltip
  profit = string.gsub(profit, "[^%d]", "")
  value = string.gsub(value, "[^%d]", "")

  print("Profit (in cents): " .. tonumber(profit))
  print("Value (in cents): " .. tonumber(value))
  
  local security = {
    name = "Account",
    price = tonumber(value) / 100,
    quantity = 1,
    purchasePrice = (tonumber(value) - tonumber(profit)) / 100,
    curreny = nil,
  }

  table.insert(s, security)

  return {securities = s}
end


function EndSession ()
  connection:get("https://www.bondora.com/de/authorize/logout/")
  return nil
end
