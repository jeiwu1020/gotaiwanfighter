"""Original low-level finite test score and cues. Rebuildable samples, no runtime oscillator loop."""
from pathlib import Path
import numpy as np,wave
root=Path(__file__).resolve().parent.parent/'assets/audio';root.mkdir(parents=True,exist_ok=True)
rate=22050;rng=np.random.default_rng(729)
def save(name,a):
 a=np.clip(a,-.85,.85)
 with wave.open(str(root/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes((a*32767).astype('<i2').tobytes())
for name,f,duration,noise in [('hit',90,.18,.3),('block',580,.13,.06),('swing',200,.11,.5),('ui',520,.06,0),('release',65,.55,.22),('ko',85,.8,.08),('fight',330,.22,0),('cinematic',140,.45,.08)]:
 t=np.arange(int(rate*duration))/rate;env=np.minimum(t/.009,1)*np.exp(-t*8/duration)
 a=(np.sin(2*np.pi*f*t*(1-t*.5))*.36+rng.normal(0,noise,len(t))*.2)*env
 save(name,a)
# Sparse, through-composed 36s pad/pluck cue with an ending, never a loop.
t=np.arange(rate*36)/rate;a=np.zeros(len(t))
for onset,midi in [(0,50),(2.8,57),(5.1,62),(8.2,53),(11.5,60),(14.4,65),(18,48),(21,55),(24,60),(27,50),(30,57),(32,62)]:
 local=t-onset;gate=local>=0;freq=440*2**((midi-69)/12)
 env=np.where(gate,np.minimum(np.maximum(local,0)/.2,1)*np.exp(-np.maximum(local,0)/2.8),0)
 a+=env*(np.sin(2*np.pi*freq*local)+.25*np.sin(2*np.pi*freq*2*local))*.09
a*=np.minimum((36-t)/3,1);save('night-cue',a)
noise=rng.normal(0,.11,rate*30);smooth=np.convolve(noise,np.ones(9)/9,mode='same');env=np.minimum(np.arange(len(noise))/rate,1)*np.minimum((len(noise)-np.arange(len(noise)))/rate,1)
save('rain',smooth*env)
print('Finite 36s score, 30s rain, eight separated cues; no loops')
