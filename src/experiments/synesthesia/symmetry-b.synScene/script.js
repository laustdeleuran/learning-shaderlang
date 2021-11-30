var lastTime = 0;
var time = 0;

function update(dt) {
	time += inputs.TIME - lastTime;
	lastTime = inputs.TIME;
	if (inputs.force_reset) time = 0;
	uniforms.script_time = time;
}
