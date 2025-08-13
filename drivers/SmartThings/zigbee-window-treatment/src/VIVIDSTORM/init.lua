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
local custom_clusters = require "VIVIDSTORM/custom_clusters"
local cluster_base = require "st.zigbee.cluster_base"
local WindowCovering = zcl_clusters.WindowCovering
local log = require "log"

local MOST_RECENT_SETLEVEL = "windowShade_recent_setlevel"
local LEVEL_UPDATE_TIMEOUT = "windowShade_update_timeout"

local most_recent_setlevel = 0
--local timer

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

local function send_read_attr_request(device, cluster, attr)
  device:send(
    cluster_base.read_manufacturer_specific_attribute(
      device,
      cluster.id,
      attr.id,
      cluster.mfg_specific_code
    )
  )
end

local function mode_attr_handler(driver, device, value, zb_rx)
  if value.value == 0 then
    device:emit_component_event(device.profile.components.Setlimit,capabilities.mode.mode("删除上限位"))
  elseif value.value == 1 then
    device:emit_component_event(device.profile.components.Setlimit,capabilities.mode.mode("设置上限位"))
  elseif value.value == 2 then
    device:emit_component_event(device.profile.components.Setlimit,capabilities.mode.mode("删除下限位"))
  elseif value.value == 3 then
    device:emit_component_event(device.profile.components.Setlimit,capabilities.mode.mode("设置下限位"))
  end
end

local function liftPercentage_attr_handler(driver, device, value, zb_rx)
  --local most_recent_setlevel = device:get_field(MOST_RECENT_SETLEVEL)
    if value.value and most_recent_setlevel and value.value ~= most_recent_setlevel then
      if value.value > most_recent_setlevel then
        device:emit_component_event(device.profile.components.Open,capabilities.windowShade.windowShade.opening())
      elseif value.value < most_recent_setlevel then
        device:emit_component_event(device.profile.components.Open,capabilities.windowShade.windowShade.closing())
      end
    end
  --device:set_field(MOST_RECENT_SETLEVEL, value.value)
  most_recent_setlevel = value.value
--[[  local timer = device:get_field(LEVEL_UPDATE_TIMEOUT)
  if timer then
    device.thread.cancel_timer(timer)
	device:set_field(LEVEL_UPDATE_TIMEOUT, nil)
  end--]]
  device.thread:call_with_delay(10, function ()
    --device:set_field(LEVEL_UPDATE_TIMEOUT, nil)
    if most_recent_setlevel == 0 then
      device:emit_component_event(device.profile.components.Open,capabilities.windowShade.windowShade.closed())
    elseif most_recent_setlevel == 100 then
      device:emit_component_event(device.profile.components.Open,capabilities.windowShade.windowShade.open())
    else
      device:emit_component_event(device.profile.components.Open,capabilities.windowShade.windowShade.partially_open())
    end
  end)
  --[[if timer then
    device:set_field(LEVEL_UPDATE_TIMEOUT, timer)
  end--]]
end

local function hardwareFault_attr_handler(driver, device, value, zb_rx)
  if value.value == 1 then
    device:emit_component_event(device.profile.components.hardwareFault,capabilities.hardwareFault.hardwareFault.detected())
  elseif value.value == 0 then
    device:emit_component_event(device.profile.components.hardwareFault,capabilities.hardwareFault.hardwareFault.clear())
  end
end

local function status_attr_handler(driver, device, value, zb_rx)
  if value.value == 0 then
    device:emit_component_event(device.profile.components.hardwareFault,capabilities.hardwareFault.hardwareFault.open())
  elseif value.value == 1 then
    device:emit_component_event(device.profile.components.hardwareFault,capabilities.hardwareFault.hardwareFault.closed())
  elseif value.value == 2 then
    device:emit_component_event(device.profile.components.hardwareFault,capabilities.hardwareFault.hardwareFault.partially_open())
  elseif value.value == 3 then
    device:emit_component_event(device.profile.components.hardwareFault,capabilities.hardwareFault.hardwareFault.opening())
  elseif value.value == 4 then
    device:emit_component_event(device.profile.components.hardwareFault,capabilities.hardwareFault.hardwareFault.closing())
  end
end

local function capabilities_mode_handler(driver, device, command)
  if command.args.mode == "删除上限位" then
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
  elseif command.args.mode == "设置上限位" then
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
  elseif command.args.mode == "删除下限位" then
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
  elseif command.args.mode == "设置下限位" then
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

local function do_refresh(driver, device)
  device:send(WindowCovering.attributes.CurrentPositionLiftPercentage:read(device):to_endpoint(0x01))
  send_read_attr_request(device, custom_clusters.motor, custom_clusters.motor.attributes.mode_value)
  send_read_attr_request(device, custom_clusters.motor, custom_clusters.motor.attributes.hardwareFault)
end

local function added_handler(self, device)
  device:emit_component_event(device.profile.components.Setlimit,capabilities.mode.supportedModes({"删除上限位", "设置上限位", "删除下限位", "设置下限位"}))
  device:emit_component_event(device.profile.components.Setlimit,capabilities.mode.mode("删除上限位"))
  device:emit_component_event(device.profile.components.hardwareFault,capabilities.hardwareFault.hardwareFault.clear())
  do_refresh(self, device)
end

local screen_handler = {
  NAME = "VWSDSTUST120H Device Handler",
  supported_capabilities = {
    capabilities.refresh
  },
  lifecycle_handlers = {
    added = added_handler
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = do_refresh
    },
    [capabilities.mode.ID] = {
      [capabilities.mode.commands.setMode.NAME] = capabilities_mode_handler
    },
  },
  zigbee_handlers = {
    attr = {
	  [WindowCovering.ID] = {
        [WindowCovering.attributes.CurrentPositionLiftPercentage.ID] = liftPercentage_attr_handler
      },
      [custom_clusters.motor.id] = {
        [custom_clusters.motor.attributes.mode_value.id] = mode_attr_handler,
        [custom_clusters.motor.attributes.hardwareFault.id] = hardwareFault_attr_handler,
		[custom_clusters.motor.attributes.status_value.id] = status_attr_handler
      }
    }
  },
  can_handle = is_zigbee_window_shade,
}

return screen_handler
