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
local function process_control_attr_factory(cmd)
  return function(driver, device, value, zb_rx)
    if value.value == 0 then
      device:emit_event(cmd.up())
    elseif value.value == 1 then
      device:emit_event(cmd.down())
    end
  end
end

local function process_massage_attr_factory(cmd)
  return function(driver, device, value, zb_rx)
    local data = value.value
    if cmd == custom_capabilities.massage_control.frequency then
      data = value.value + 1
    end
    device:emit_event(cmd(data))
  end
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

local function process_massage_control_cap_factory(cap,attrs)
  return function(driver, device, cmd)
    local payload = cmd.args[cap]
    if cap == "frequencyControl" then
      payload = payload-1
    end
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.shus_smart_bedstead.id,
        custom_clusters.shus_smart_bedstead.attributes[attrs].id,
        custom_clusters.shus_smart_bedstead.mfg_specific_code,
        custom_clusters.shus_smart_bedstead.attributes[attrs].value_type,
        payload
    )
    )
  end
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


local function process_movement_control_cap_factory(cap,attrs,cap_attr)
  return function(driver, device, cmd)
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.shus_smart_bedstead.id,
        custom_clusters.shus_smart_bedstead.attributes[attrs].id,
        custom_clusters.shus_smart_bedstead.mfg_specific_code,
        custom_clusters.shus_smart_bedstead.attributes[attrs].value_type,
        custom_clusters.shus_smart_bedstead.attributes[attrs].value[cmd.args[cap]]
    )
    )
    --Since the same button is triggered on the APP and the same event will be emit by the driver,
    --the APP will pop up an error. Therefore, an opposite event needs to be triggered to ensure that
    --the user will not receive an error when continuously triggering the same button
    local event = cap_attr.down()
    local event1 = cap_attr.idle()
    if cmd.args[cap] == "up" then
        event = cap_attr.up()
    end
    device:emit_event(event)
    socket.sleep(1)
    device:emit_event(event1)
  end
end

-- #############################
-- # Lifecycle handlers define #
-- #############################

local function device_init(driver, device)
end

local function device_added(driver, device)
  device:emit_event(custom_capabilities.movement_control.back.down())
  device:emit_event(custom_capabilities.movement_control.leg.down())
  device:emit_event(custom_capabilities.movement_control.backLeg.down())
  do_refresh(driver, device)
end

local function do_configure(driver, device)
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
        [custom_clusters.shus_smart_bedstead.attributes.back_control.id] = process_control_attr_factory(custom_capabilities.movement_control.back),
        [custom_clusters.shus_smart_bedstead.attributes.leg_control.id] = process_control_attr_factory(custom_capabilities.movement_control.leg),
        [custom_clusters.shus_smart_bedstead.attributes.back_leg_control.id] = process_control_attr_factory(custom_capabilities.movement_control.backLeg),
        [custom_clusters.shus_smart_bedstead.attributes.back_massage.id] = process_massage_attr_factory(custom_capabilities.massage_control.backStrength),
        [custom_clusters.shus_smart_bedstead.attributes.leg_massage.id] = process_massage_attr_factory(custom_capabilities.massage_control.legStrength),
        [custom_clusters.shus_smart_bedstead.attributes.massage_frequency.id] = process_massage_attr_factory(custom_capabilities.massage_control.frequency),
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
      ["backControl"] = process_movement_control_cap_factory("backControl","back_control",custom_capabilities.movement_control.back),
      ["legControl"] = process_movement_control_cap_factory("legControl","leg_control",custom_capabilities.movement_control.leg),
      ["backLegControl"] = process_movement_control_cap_factory("backLegControl","back_leg_control",custom_capabilities.movement_control.backLeg)
    },
    [custom_capabilities.massage_control.ID] = {
      ["stateControl"] = massage_control_state_cap_handler,
      ["backStrengthControl"] = process_massage_control_cap_factory("backStrengthControl","back_massage"),
      ["legStrengthControl"] = process_massage_control_cap_factory("legStrengthControl","leg_massage"),
      ["frequencyControl"] = process_massage_control_cap_factory("frequencyControl","massage_frequency")
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
