local ReplicatedStorage = game:GetService("ReplicatedStorage")
local API = ReplicatedStorage:WaitForChild("API")

local Success, ErrorMessage = pcall(function()
  for RemoteName, HashedRemote in getupvalue(require(ReplicatedStorage.ClientModules.Core.RouterClient.RouterClient).init, 7) do
    if typeof(HashedRemote) ~= "Instance" then return end
    if HashedRemote.Parent ~= API then return end
    if not (HashedRemote:IsA("RemoteEvent") or HashedRemote:IsA("RemoteFunction")) then return end
    HashedRemote.Name = RemoteName
  end
end)

if not Success then
  warn("Error rendering API:", ErrorMessage)
  return
end

print("Rendered API successfully.")
