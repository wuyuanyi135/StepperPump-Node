---------------------------------------
node.setcpufreq(node.CPU160MHZ)

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
function update() 
    if direction then
        gpio.write(pin_dir,gpio.HIGH)
    else
        gpio.write(pin_dir,gpio.LOW)    
    end
   
    if tick_per_sec ~= 0 then
        pwm2.stop()
        gpio.write(pin_en, gpio.LOW)
        pwm2.setup_pin_hz(pin_step,tick_per_sec, 2, 1)
        pwm2.start()
    else
        gpio.write(pin_en, gpio.HIGH)
        pwm2.stop()
    end
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