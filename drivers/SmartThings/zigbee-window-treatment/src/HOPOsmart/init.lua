-- Copyright 2025 SmartThings
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

local zcl_clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"
local custom_clusters = require "HOPOsmart/custom_clusters"
local cluster_base = require "st.zigbee.cluster_base"
local log = require "log"

local ZIGBEE_WINDOW_SHADE_FINGERPRINTS = {
    { mfr = "HOPOsmart", model = "HOPOsmart" }
}

local is_zigbee_window_shade = function(opts, driver, device)
  for _, fingerprint in ipairs(ZIGBEE_WINDOW_SHADE_FINGERPRINTS) do
      if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
          return true
      end
  end
  return false
end

local function capabilities_momentary_handler(driver, device, command)
  if command.component == "Open" then
	device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.motor.id,
        custom_clusters.motor.attributes.mode_value.id,
        custom_clusters.motor.mfg_specific_code,
        custom_clusters.motor.attributes.mode_value.value_type,
        0
      )
    )
  elseif command.component == "Hang" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.motor.id,
        custom_clusters.motor.attributes.mode_value.id,
        custom_clusters.motor.mfg_specific_code,
        custom_clusters.motor.attributes.mode_value.value_type,
        1
      )
    )
	elseif command.component == "Puse" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.motor.id,
        custom_clusters.motor.attributes.mode_value.id,
        custom_clusters.motor.mfg_specific_code,
        custom_clusters.motor.attributes.mode_value.value_type,
        2
      )
    )
	elseif command.component == "Close" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.motor.id,
        custom_clusters.motor.attributes.mode_value.id,
        custom_clusters.motor.mfg_specific_code,
        custom_clusters.motor.attributes.mode_value.value_type,
        3
      )
    )
	end
end

local HOPOsmart_handler = {
  NAME = "HOPOsmart Device Handler",
  capability_handlers = {
	[capabilities.momentary.ID] = {
      [capabilities.momentary.commands.push.NAME] = capabilities_momentary_handler
    }
  },
  can_handle = is_zigbee_window_shade,
}

return HOPOsmart_handler
