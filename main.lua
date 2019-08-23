ID = "PC"..node.chipid()
pin_step = 2
pin_dir = 1
pin_en = 5

gpio.mode(pin_step, gpio.OUTPUT)
gpio.mode(pin_en, gpio.OUTPUT)
gpio.mode(pin_dir, gpio.OUTPUT)
gpio.write(pin_step,gpio.LOW)    
gpio.write(pin_dir,gpio.LOW)    
gpio.write(pin_en, gpio.HIGH) --- disabled
----------------------------------------
tick_per_sec = 0
direction = 0
----------------------------------------
step_timer = tmr.create()
shutdown_timer = tmr.create()
shutdown_timer:register(1, tmr.ALARM_SEMI, function()
    gpio.write(pin_step,gpio.LOW)
end)
function update() 
    if direction then
        gpio.write(pin_dir,gpio.HIGH)
    else
        gpio.write(pin_dir,gpio.LOW)    
    end
    
    step_timer:stop()
    step_timer:unregister()

    gpio.write(pin_en, gpio.HIGH)

    if tick_per_sec ~= 0 then
        gpio.write(pin_en, gpio.LOW)
        step_timer:register(1000/tick_per_sec, tmr.ALARM_AUTO, function()
            
            gpio.write(pin_step,gpio.HIGH)
            shutdown_timer:start()
        end)
    end
    step_timer:start()
end
----------------------------------------
station_cfg={}
station_cfg.ssid="DCHost"
station_cfg.pwd="dchost000000"
station_cfg.got_ip_cb = function(ip, mask, gateway)
    print("Got ip")
    m = mqtt.Client(ID, 60)
    m:on("message", function(client, topic, data)
        print(topic, data)
        if topic == ID.."/direction" then
            direction = tonumber(data)
        end
        if topic == ID.."/tps" then
            tick_per_sec = tonumber(data)
        end
        update()
    end)

    m:connect("192.168.43.1", 1883, false, function()
        print("MQTT Connected")
        m:subscribe(ID.."/direction", 0)
        m:subscribe(ID.."/tps", 0)
    end, function(client, reason)
        print("failed reason: " .. reason)
        node.restart()
    end)

end
wifi.setmode(wifi.STATION, true)
wifi.sta.config(station_cfg)