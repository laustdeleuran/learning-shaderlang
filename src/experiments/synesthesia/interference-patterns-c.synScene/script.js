var bassT = 0.0;
var colorTime = 0;
var lastBPMTwitcher = 0;

function update(dt) {
	bassT +=
		Math.pow(inputs.syn_BassLevel, 1.9) * (dt * 60) * inputs.auto_in * 0.25;
	uniforms.script_bass_time = bassT;

	var deltaBPMTwitcher = inputs.syn_BPMTwitcher - lastBPMTwitcher;
	lastBPMTwitcher = inputs.syn_BPMTwitcher;
	colorTime += deltaBPMTwitcher / (20 - inputs.color_speed * 2);
	uniforms.script_color_time = colorTime;
}
