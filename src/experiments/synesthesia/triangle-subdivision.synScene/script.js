var rotationTime = 0.0;
var lastTime = 0;

function update(dt) {
	deltaTime = inputs.TIME - lastTime;
	lastTime = inputs.TIME;
	rotationTime += deltaTime * inputs.rotation * inputs.speed;
	uniforms.script_rotationTime = rotationTime;
}
