import subprocess

def camera_in_use():
    try:
        output = subprocess.check_output(["pgrep", "-x", "AppleCameraAssistant"])
        print("1")  # Caméra active
    except subprocess.CalledProcessError:
        print("0")  # Caméra inactive

camera_in_use()
