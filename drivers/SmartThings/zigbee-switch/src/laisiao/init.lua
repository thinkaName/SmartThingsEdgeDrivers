-- Copyright 2023 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local capabilities = require "st.capabilities"
local log = require "log"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local OnOff = zcl_clusters.OnOff

local FINGERPRINTS = {
  { mfr = "LAISIAO", model = "yuba" },
}

local function can_handle_laisiao(opts, driver, device, ...)
  for _, fingerprint in ipairs(FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      local subdriver = require("laisiao")
      return true, subdriver
    end
  end
  return false
end

local function device_added(driver, device)
end

local function component_to_endpoint(device, component_id)
  if component_id == "main" then
    return device.fingerprinted_endpoint_id
  else
    local ep_num = component_id:match("switch(%d)")
    return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
  end
end

local function endpoint_to_component(device, ep)
  if ep == device.fingerprinted_endpoint_id then
    return "main"
  else
    return string.format("switch%d", ep)
  end
end

local device_init = function(self, device)
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)
end

local function on_off_attr_handler(driver, device, value, zb_rx)
  local attr = capabilities.switch.switch
  device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, value.value and attr.on() or attr.off())
end

local function on_handler(driver, device, command)
  log.error("Enter on_handler",command.component)
  local attr = capabilities.switch.switch
  if command.component == "main" then
    -- The main component is set to on by the device and cannot be set to on itself. It can only trigger off
    device:emit_event_for_endpoint(1, attr.on())
    device:emit_event_for_endpoint(1, attr.off())
  else
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.On(device))
  end
end

local function off_handler(driver, device, command)
  device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.Off(device))
end

local laisiao_bath_heater = {
  NAME = "Zigbee Laisiao Bath Heater",
  supported_capabilities = {
    capabilities.switch,
  },
  lifecycle_handlers = {
    added = device_added,
    init = device_init,
  },
  zigbee_handlers = {
    attr = {
      [OnOff.ID] = {
        [OnOff.attributes.OnOff.ID] = on_off_attr_handler
      }
    }
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on_handler,
      [capabilities.switch.commands.off.NAME] = off_handler
    }
  },
  can_handle = can_handle_laisiao
}

return laisiao_bath_heater
