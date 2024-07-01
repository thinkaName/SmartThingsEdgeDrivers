-- Copyright 2024 SmartThings
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
local cluster_base = require "st.zigbee.cluster_base"
local custom_clusters = require "shus/custom_clusters"
local custom_capabilities = require "shus/custom_capabilities"
local socket = require "cosock.socket"

local FINGERPRINTS = {
  { mfr = "SHUS", model = "2123" }
}

-- #############################
-- # Attribute handlers define #
-- #############################
local function back_control_attr_handler(driver, device, value, zb_rx)
  if value.value == custom_clusters.shus_smart_bedstead.attributes.back_control.value.up then
    device:emit_event(custom_capabilities.movement_control.back.up())
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.back_control.value.down then
    device:emit_event(custom_capabilities.movement_control.back.down())
end

local function leg_control_attr_handler(driver, device, value, zb_rx)
  if value.value == custom_clusters.shus_smart_bedstead.attributes.leg_control.value.up then
    device:emit_event(custom_capabilities.movement_control.leg.up())
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.leg_control.value.down then
    device:emit_event(custom_capabilities.movement_control.leg.down())
end

local function back_leg_control_attr_handler(driver, device, value, zb_rx)
  if value.value == custom_clusters.shus_smart_bedstead.attributes.back_leg_control.value.up then
    device:emit_event(custom_capabilities.movement_control.backLeg.up())
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.back_leg_control.value.down then
    device:emit_event(custom_capabilities.movement_control.backLeg.down())
end

local function back_massage_attr_handler(driver, device, value, zb_rx)
  device:emit_event(custom_capabilities.massage_control.backStrength(value.value))
end

local function leg_massage_attr_handler(driver, device, value, zb_rx)
  device:emit_event(custom_capabilities.massage_control.legStrength(value.value))
end

local function massage_frequency_attr_handler(driver, device, value, zb_rx)
  device:emit_event(custom_capabilities.massage_control.frequency(value.value + 1))
end

local function massage_switch_attr_handler(driver, device, value, zb_rx)
  local state_value = "off"
  if value.value == custom_clusters.shus_smart_bedstead.attributes.massage_switch.value.m_10 then
    state_value = "10M"
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.massage_switch.value.m_20 then
    state_value = "20M"
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.massage_switch.value.m_30 then
    state_value = "30M"
  end

  device:emit_event(custom_capabilities.massage_control.state(state_value))
end

local function mode_attr_handler(driver, device, value, zb_rx)
  local state_value = "stop"
  if value.value == custom_clusters.shus_smart_bedstead.attributes.mode.value.zero_gravity then
    state_value = "zeroGravity"
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.mode.value.leisure then
    state_value = "leisure"
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.mode.value.snoring_intervention then
    state_value = "snoringIntervention"
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.mode.value.reading then
    state_value = "reading"
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.mode.value.lying_flat then
    state_value = "lyingFlat"
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.mode.value.comfort then
    state_value = "comfort"
  end

  device:emit_event(custom_capabilities.mode.state(state_value))
end

local function night_light_attr_handler(driver, device, value, zb_rx)
  local state_value = "off"
  if value.value == custom_clusters.shus_smart_bedstead.attributes.night_light.value.m_10 then
    state_value = "10M"
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.night_light.value.h_8 then
    state_value = "8H"
  elseif value.value == custom_clusters.shus_smart_bedstead.attributes.night_light.value.h_10 then
    state_value = "10H"
  end

  device:emit_event(custom_capabilities.night_light.state(state_value))
end

-- ##############################
-- # Capability handlers define #
-- ##############################

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

local function do_refresh(driver, device)
  send_read_attr_request(device, custom_clusters.shus_smart_bedstead, custom_clusters.shus_smart_bedstead.attributes.back_massage)
  send_read_attr_request(device, custom_clusters.shus_smart_bedstead, custom_clusters.shus_smart_bedstead.attributes.leg_massage)
  send_read_attr_request(device, custom_clusters.shus_smart_bedstead, custom_clusters.shus_smart_bedstead.attributes.massage_frequency)
  send_read_attr_request(device, custom_clusters.shus_smart_bedstead, custom_clusters.shus_smart_bedstead.attributes.massage_switch)
  send_read_attr_request(device, custom_clusters.shus_smart_bedstead, custom_clusters.shus_smart_bedstead.attributes.mode)
  send_read_attr_request(device, custom_clusters.shus_smart_bedstead, custom_clusters.shus_smart_bedstead.attributes.night_light)
end

local function process_up_down_cap(device, value, cluster, attr, cap_attr)
  local payload = attr.value.down
  local event = cap_attr.up()

  if value == "up" then
    payload = attr.value.up
    event = cap_attr.down()
  end

  device:send(
    cluster_base.write_manufacturer_specific_attribute(
      device,
      cluster.id,
      attr.id,
      cluster.mfg_specific_code,
      attr.value_type,
      payload
    )
  )

  -- Since back/leg/backLeg control attributes do not support reporting,
  -- So we need to actively emit_event instead of waiting for attribute callback.
  -- Since the mechanical structure takes about 1 second to run,
  -- we added a 1 second delay before emit_event
  socket.sleep(1)

  device:emit_event(event)

end

local function movement_control_back_cap_handler(driver, device, cmd)

  process_up_down_cap(
    device,
    cmd.args.backControl,
    custom_clusters.shus_smart_bedstead,
    custom_clusters.shus_smart_bedstead.attributes.back_control,
    custom_capabilities.movement_control.back
  )
end

local function movement_control_leg_cap_handler(driver, device, cmd)
  process_up_down_cap(
    device,
    cmd.args.legControl,
    custom_clusters.shus_smart_bedstead,
    custom_clusters.shus_smart_bedstead.attributes.leg_control,
    custom_capabilities.movement_control.leg
  )
end

local function movement_control_back_leg_cap_handler(driver, device, cmd)
  process_up_down_cap(
    device,
    cmd.args.backLegControl,
    custom_clusters.shus_smart_bedstead,
    custom_clusters.shus_smart_bedstead.attributes.back_leg_control,
    custom_capabilities.movement_control.backLeg
  )
end

local function massage_control_state_cap_handler(driver, device, cmd)
  local payload = custom_clusters.shus_smart_bedstead.attributes.massage_switch.value.off
  if cmd.args.stateControl == "10M" then
    payload = custom_clusters.shus_smart_bedstead.attributes.massage_switch.value.m_10
  elseif cmd.args.stateControl == "20M" then
    payload = custom_clusters.shus_smart_bedstead.attributes.massage_switch.value.m_20
  elseif cmd.args.stateControl == "30M" then
    payload = custom_clusters.shus_smart_bedstead.attributes.massage_switch.value.m_30
  end

  device:send(
    cluster_base.write_manufacturer_specific_attribute(
      device,
      custom_clusters.shus_smart_bedstead.id,
      custom_clusters.shus_smart_bedstead.attributes.massage_switch.id,
      custom_clusters.shus_smart_bedstead.mfg_specific_code,
      custom_clusters.shus_smart_bedstead.attributes.massage_switch.value_type,
      payload
    )
  )
end

local function massage_control_back_strength_cap_handler(driver, device, cmd)
print("massage_control_back_strength_cap_handler")
  device:send(
    cluster_base.write_manufacturer_specific_attribute(
      device,
      custom_clusters.shus_smart_bedstead.id,
      custom_clusters.shus_smart_bedstead.attributes.back_massage.id,
      custom_clusters.shus_smart_bedstead.mfg_specific_code,
      custom_clusters.shus_smart_bedstead.attributes.back_massage.value_type,
      cmd.args.backStrengthControl
    )
  )
end

local function massage_control_leg_strength_cap_handler(driver, device, cmd)
  device:send(
    cluster_base.write_manufacturer_specific_attribute(
      device,
      custom_clusters.shus_smart_bedstead.id,
      custom_clusters.shus_smart_bedstead.attributes.leg_massage.id,
      custom_clusters.shus_smart_bedstead.mfg_specific_code,
      custom_clusters.shus_smart_bedstead.attributes.leg_massage.value_type,
      cmd.args.legStrengthControl
    )
  )
end

local function massage_control_frequency_cap_handler(driver, device, cmd)
  device:send(
    cluster_base.write_manufacturer_specific_attribute(
      device,
      custom_clusters.shus_smart_bedstead.id,
      custom_clusters.shus_smart_bedstead.attributes.massage_frequency.id,
      custom_clusters.shus_smart_bedstead.mfg_specific_code,
      custom_clusters.shus_smart_bedstead.attributes.massage_frequency.value_type,
      cmd.args.frequencyControl - 1
    )
  )
end

local function mode_cap_handler(driver, device, cmd)
  local payload = custom_clusters.shus_smart_bedstead.attributes.mode.value.stop
  if cmd.args.stateControl == "zeroGravity" then
    payload = custom_clusters.shus_smart_bedstead.attributes.mode.value.zero_gravity
  elseif cmd.args.stateControl == "leisure" then
    payload = custom_clusters.shus_smart_bedstead.attributes.mode.value.leisure
  elseif cmd.args.stateControl == "snoringIntervention" then
    payload = custom_clusters.shus_smart_bedstead.attributes.mode.value.snoring_intervention
  elseif cmd.args.stateControl == "reading" then
    payload = custom_clusters.shus_smart_bedstead.attributes.mode.value.reading
  elseif cmd.args.stateControl == "lyingFlat" then
    payload = custom_clusters.shus_smart_bedstead.attributes.mode.value.lying_flat
  elseif cmd.args.stateControl == "comfort" then
    payload = custom_clusters.shus_smart_bedstead.attributes.mode.value.comfort
  end

  device:send(
    cluster_base.write_manufacturer_specific_attribute(
      device,
      custom_clusters.shus_smart_bedstead.id,
      custom_clusters.shus_smart_bedstead.attributes.mode.id,
      custom_clusters.shus_smart_bedstead.mfg_specific_code,
      custom_clusters.shus_smart_bedstead.attributes.mode.value_type,
      payload
    )
  )
end

local function night_light_cap_handler(driver, device, cmd)
  local payload = custom_clusters.shus_smart_bedstead.attributes.night_light.value.stop
  if cmd.args.stateControl == "off" then
    payload = custom_clusters.shus_smart_bedstead.attributes.night_light.value.off
  elseif cmd.args.stateControl == "10M" then
    payload = custom_clusters.shus_smart_bedstead.attributes.night_light.value.m_10
  elseif cmd.args.stateControl == "8H" then
    payload = custom_clusters.shus_smart_bedstead.attributes.night_light.value.h_8
  elseif cmd.args.stateControl == "10H" then
    payload = custom_clusters.shus_smart_bedstead.attributes.night_light.value.h_10
  end

  device:send(
    cluster_base.write_manufacturer_specific_attribute(
      device,
      custom_clusters.shus_smart_bedstead.id,
      custom_clusters.shus_smart_bedstead.attributes.night_light.id,
      custom_clusters.shus_smart_bedstead.mfg_specific_code,
      custom_clusters.shus_smart_bedstead.attributes.night_light.value_type,
      payload
    )
  )
end

-- #############################
-- # Lifecycle handlers define #
-- #############################

local function device_init(driver, device)
  -- TODO
end

local function device_added(driver, device)
  device:emit_event(custom_capabilities.movement_control.back.down())
  device:emit_event(custom_capabilities.movement_control.leg.down())
  device:emit_event(custom_capabilities.movement_control.backLeg.down())
  do_refresh(driver, device)
end

local function do_configure(driver, device)
  -- TODO
end

local function is_shus_products(opts, driver, device)
  for _, fingerprint in ipairs(FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end

-- #################
-- # Handlers bind #
-- #################

local shus_smart_bedstead = {
  NAME = "Shus Smart Bedstead",
  supported_capabilities = {
    capabilities.refresh
  },
  lifecycle_handlers = {
    init = device_init,
    added = device_added,
    doConfigure = do_configure
  },
  zigbee_handlers = {
    attr = {
      [custom_clusters.shus_smart_bedstead.id] = {
		[custom_clusters.shus_smart_bedstead.attributes.back_control.id] = back_control_attr_handler,
        [custom_clusters.shus_smart_bedstead.attributes.leg_control.id] = leg_control_attr_handler,
        [custom_clusters.shus_smart_bedstead.attributes.back_leg_control.id] = back_leg_control_attr_handler,
        [custom_clusters.shus_smart_bedstead.attributes.back_massage.id] = back_massage_attr_handler,
        [custom_clusters.shus_smart_bedstead.attributes.leg_massage.id] = leg_massage_attr_handler,
        [custom_clusters.shus_smart_bedstead.attributes.massage_frequency.id] = massage_frequency_attr_handler,
        [custom_clusters.shus_smart_bedstead.attributes.massage_switch.id] = massage_switch_attr_handler,
        [custom_clusters.shus_smart_bedstead.attributes.mode.id] = mode_attr_handler,
        [custom_clusters.shus_smart_bedstead.attributes.night_light.id] = night_light_attr_handler,
      }
    }
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = do_refresh
    },
    [custom_capabilities.movement_control.ID] = {
      ["backControl"] = movement_control_back_cap_handler,
      ["legControl"] = movement_control_leg_cap_handler,
      ["backLegControl"] = movement_control_back_leg_cap_handler
    },
    [custom_capabilities.massage_control.ID] = {
      ["stateControl"] = massage_control_state_cap_handler,
      ["backStrengthControl"] = massage_control_back_strength_cap_handler,
      ["legStrengthControl"] = massage_control_leg_strength_cap_handler,
      ["frequencyControl"] = massage_control_frequency_cap_handler
    },
    [custom_capabilities.mode.ID] = {
      ["stateControl"] = mode_cap_handler
    },
    [custom_capabilities.night_light.ID] = {
      ["stateControl"] = night_light_cap_handler
    }
  },
  can_handle = is_shus_products
}

return shus_smart_bedstead
