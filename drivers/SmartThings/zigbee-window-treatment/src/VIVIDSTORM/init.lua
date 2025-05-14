-- Copyright 2022 SmartThings
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
local utils = require "st.utils"
local window_preset_defaults = require "st.zigbee.defaults.windowShadePreset_defaults"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local WindowCovering = zcl_clusters.WindowCovering

local GLYDEA_MOVE_THRESHOLD = 3

local ZIGBEE_WINDOW_SHADE_FINGERPRINTS = {
    { mfr = "VIVIDSTORM", model = "VWSDSTUST120H" }
}


local is_zigbee_window_shade = function(opts, driver, device)
  for _, fingerprint in ipairs(ZIGBEE_WINDOW_SHADE_FINGERPRINTS) do
      if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
          return true
      end
  end
  return false
end

local function do_refresh(driver, device)
end

local function added_handler(self, device)
  device:emit_event(capabilities.mode.supportedModes({"Set upper limit", "Delete all limits"}))
  do_refresh()
end

local somfy_handler = {
  NAME = "VWSDSTUST120H Device Handler",
  lifecycle_handlers = {
    added = added_handler
  },
  capability_handlers = {
    [capabilities.mode.ID] = {
      [capabilities.mode.commands.setShadeLevel.NAME] = window_shade_level_cmd
    },
  },
  zigbee_handlers = {
    attr = {
      [WindowCovering.ID] = {
        [WindowCovering.attributes.CurrentPositionLiftPercentage.ID] = current_position_attr_handler,
        [WindowCovering.attributes.PhysicalClosedLimitLift.ID] = movement_ended_handler
      }
    }
  },
  can_handle = is_zigbee_window_shade,
}

return somfy_handler
