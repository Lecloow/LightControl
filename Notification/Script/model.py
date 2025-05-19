from busylight.lights.embrava import Blynclight
import time

light = Blynclight.first_light()

light.on((255, 138, 0))
#time.sleep(5)
#light.off()