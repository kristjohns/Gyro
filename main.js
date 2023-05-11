
//const { TextGeometry } = window.THREE;

window.addEventListener('load', function() {

  console.log=function(){};

//-----------------------START THREEJS CODE ----------------------


var i = 0;
var R1 = R1_both();
var gimbal = gim_both();
var o2 = o2_both();
var o3 = o3_both();




var car;
var PI = Math.PI;
const scene = new THREE.Scene();
scene.background = new THREE.Color(0xADD8E6);

const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 5000);

var renderer = new THREE.WebGLRenderer({
  canvas: document.querySelector('#bg'),
  
});

//renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(window.innerWidth, window.innerHeight);
camera.position.setZ(150);
camera.position.setX(700);
camera.position.setY(500);



const controls = new THREE.OrbitControls(camera, renderer.domElement);
controls.minDistance = 150; //Sets the minimum distance one can pan into the scene
controls.maxDistance = 500;  //Sets the maximum distance one can pan away from scene
controls.minPolarAngle = 0;
controls.maxPolarAngle =  Math.PI * 0.45;
controls.enablePan = false; //diables the right click






//--------------PANE.js-------------------

// CDN
const pane = new Tweakpane.Pane({
  container: document.getElementById('my-pane')
});

const folder = pane.addFolder({
  title: 'Simulation Controls'
})

const folder2 = pane.addFolder({
  title: 'Simulation Results'
})

const folder3 = pane.addFolder({
  title: 'Hardware Videos'
})

const folder4 = pane.addFolder({
  title: 'Resumes/CVs'
})


var pitch = folder3.addButton({title: 'Pitch Hardware Video'});
var yaw = folder3.addButton({title: 'Yaw Hardware Video'});
var fight = folder3.addButton({title: 'Fighting Moment Hardware Video'});


pitch.on('click', ()=> {
  window.open("pitch.html", "_blank");
})
yaw.on('click', ()=> {
  window.open("yaw.html", "_blank");
})
fight.on('click', ()=> {
  window.open("moment.html", "_blank");
})

var KJ = folder4.addButton({title: 'Kristian Johnsen'});
var PH = folder4.addButton({title: 'Petter S. Hole'});
var JJ = folder4.addButton({title: 'Joakim H. Jacobsen'});

KJ.on('click', ()=> {
  window.open("KristianJohnsen_CV.html", "_blank");
})
PH.on('click', ()=> {
  window.open("PetterHole_CV.html", "_blank");
})
JJ.on('click', ()=> {
  window.open("JoakimJacobsen_CV.html", "_blank");
})

const params = {
  simSpeed: 0, 
  Case: 'Both Motors',
  reset: false,
  cameraAngle: false,
  pitchAngVel: 0,
  yawAngVel: 0,
  ExplodedView: false
};


// `options`: list
var cases = folder.addInput(params, 'Case',{
  options: {
    BothMotors: 'Both Motors',
    Motor1: 'Motor 1',
    Motor2: 'Motor 2'
  }
});

cases.on('change', (newValue) => {
    i = 0;
  if (params.Case == 'Both Motors') {
    R1 = R1_both();
    gimbal = gim_both();
    o2 = o2_both();
    o3 = o3_both();
    targetPosition = new THREE.Vector3(50, 100, 250);
  } else if (params.Case == 'Motor 1') {
    R1 = R1_M1();
    gimbal = gim_M1();
    targetPosition = new THREE.Vector3(200, 100, 0);
    o2 = o2_M1();
    o3 = o3_M1();
  } else if (params.Case == 'Motor 2') {
    R1 = R1_M2();
    gimbal = gim_M2();
    targetPosition = new THREE.Vector3(10, 200, 0);
    o2 = o2_M2();
    o3 = o3_M2();
  } else if (newValue == 'No Motor') {
    R1 = R1_M0();
    gimbal = gim_M0();
  }

  // Zoom in on the target position
  var tween = new TWEEN.Tween(camera.position).to({x: targetPosition.x, y: targetPosition.y, z: targetPosition.z}, 500)
  tween.start()
  tween7.start()
})  


// `min` and `max`: slider
folder.addInput(
  params, 'simSpeed',
  {min: 0, max: 10, step: 1}
);







folder.addInput(params, 'cameraAngle');
var explodedView = folder.addInput(params, 'ExplodedView');

folder.addSeparator();
folder.addSeparator();
folder.addSeparator();
folder.addSeparator();
folder.addSeparator();
folder.addSeparator();
var pause = folder.addButton({title: 'Pause Button'});

var p = 0;
pause.on('click', ()=> {
  p++
  if(p == 1){
    params.simSpeed = false;
    
  }
  else if(p == 2){
    params.simSpeed = 5;
    p = 0;
  }
})


folder2.addMonitor(params, 'pitchAngVel', {
  view: 'graph',
  min: -10,
  max: +10,
});

folder2.addMonitor(params, 'yawAngVel', {
  view: 'graph',
  min: -10,
  max: +10,
});

//--------------------------------------------------------








var car = new THREE.Object3D();

loadOBJWithMTL('models','/cardesignn.obj', '/cardesignn.mtl', object => {
  object.rotation.x =- PI/2;
  car.add(object);
});
car.position.x = -700;
car.position.y = 35;



var gimbal1 = new THREE.Object3D();
loadOBJWithMTL('models','/gi11.obj', '/gi11.mtl', object => {
  gimbal1.add(object);
});
gimbal1.position.y = 500;
gimbal1.position.x = 500;
gimbal1.position.z = -45;
gimbal1.rotation.y = PI/2;



var gyro1 = new THREE.Object3D();
loadOBJWithMTL('models','/gy222.obj', '/gy222.mtl', object => {
  gyro1.add(object);
});

gyro1.position.y = 500;
gyro1.position.x = 500;
gyro1.position.z = 500;
gyro1.rotation.y = PI/2;



var gimbal2 = new THREE.Object3D();
loadOBJWithMTL( 'models','/gi11.obj', '/gi11.mtl', object => {
  gimbal2.add(object);
});
gimbal2.position.y = 500;
gimbal2.position.x = 500;
gimbal2.position.z = 45;
gimbal2.rotation.y = -PI/2;


var motor1 = new THREE.Object3D();
loadOBJWithMTL('models','/motor.obj', '/motor.mtl', object => {
  motor1.add(object);
});

motor1.position.y = 35;
motor1.position.x = 75;
motor1.position.z = 10;
motor1.rotation.y = -PI/2;

var gyro2 = new THREE.Object3D();
loadOBJWithMTL('models','/gy222.obj', '/gy222.mtl', object => {
  object.rotation.x = PI;
  gyro2.add(object);
});
gyro2.position.y = 500;
gyro2.position.x = 500;
gyro2.position.z = 500;
gyro2.rotation.x = PI;


scene.add(car);
car.add(gimbal1);
//car.add(motor1);
gimbal1.add(gyro1);
car.add(gimbal2);
gimbal2.add(gyro2);


//******* sky *******

let sky, sun;
	
sky = new THREE.Sky();
sky.scale.setScalar( 10000 );
//sky.rotation.set(0, 0, -PI/2);
scene.add( sky );
console.log(sky.material.uniform);
sun = new THREE.Vector3(-1, 0, 0);
sky.material.uniforms.up.value.set( 0, 1, 0 );
sky.material.uniforms.sunPosition.value.copy( sun );



//------------ LIGHTS --------------
const pointLight = new THREE.DirectionalLight(0xffffff);
pointLight.position.set(-1,0,0)

const hemiLight = new THREE.AmbientLight(0xffffff, 0.8);//, 0xffffff, 0.6);
hemiLight.position.set(0,10,0);
scene.add(hemiLight);

const hemiLight1 = new THREE.PointLight(0xffffff, 0.6);//, 0xffffff, 0.6);
hemiLight1.position.set(0,2000,0);
scene.add(hemiLight1);

//const ambientLight = new THREE.AmbientLight(0xffffff);
scene.add(pointLight);//, ambientLight);

const lightHelper = new THREE.PointLightHelper(pointLight);
const gridHelper = new THREE.GridHelper(2000, 500, -100);



const texture = new THREE.TextureLoader().load('models/Road_001_basecolor.jpg');
		const ambientO = new THREE.TextureLoader().load('models/Road_001_ambientOcclusion.jpg');
		const height1 = new THREE.TextureLoader().load('models/Road_001_height.png');
		const normal = new THREE.TextureLoader().load('models/Road_001_normal.jpg');
		const roughness = new THREE.TextureLoader().load('models/Road_001_roughness.jpg');


// Create the geometry of the plane with a width and height of 10 units
var geometry = new THREE.PlaneGeometry(1000, 1000, 250, 250);

// Create a material for the plane using a basic material with a color of white
var material = new THREE.MeshStandardMaterial({ 
  color: 0xffffff,
  map: texture,
  normalMap: normal,
  displacementMap: height1,
  roughnessMap: roughness,
  roughness: 0.5

});// , transparent: true, opacity: 0.8});

var plane = new THREE.Mesh(geometry, material);
plane.rotation.x = -PI/2;
plane.position.y = 25;
plane.rotation.z = PI/2;
// Add the plane to the scene
scene.add(plane);



for(let l = 0; l<2; l++){
  var plane1 = new THREE.Mesh(geometry, material);
  plane1.position.x = -1000 - 1000*l;
  plane1.rotation.x = -PI/2;
  plane1.rotation.z = PI/2;
  plane1.position.y = 25;
  scene.add(plane1);
}


for(let l = 0; l<2; l++){
  var plane1 = new THREE.Mesh(geometry, material);
  plane1.position.x = 1000 + 1000*l;
  plane1.rotation.x = -PI/2;
  plane1.rotation.z = PI/2;
  plane1.position.y = 25;
  scene.add(plane1);
}


var R1_M = new THREE.Matrix4();
var transform = new THREE.Matrix4();
var transformrev = new THREE.Matrix4();
var R = new THREE.Matrix4();
var R_transform = new THREE.Matrix4();

transform.set(
  1, 0, 0, 0,
  0, 0, 1, 0,
  0, -1, 0, 0,
  0, 0, 0, 1  
);

transformrev.set(
  1, 0, 0, 0,
  0, 0, -1, 0,
  0, 1, 0, 0,
  0, 0, 0, 1  
);


var tween1 = new TWEEN.Tween(camera.position).to({x: 150, y: 150, z: 150}, 1000)
tween1.start()

var tween2 = new TWEEN.Tween(car.position).to({x: -75, y: 35, z: 0}, 1500)
tween2.start()

var tween3 = new TWEEN.Tween(gimbal1.position).to({x: 75, y: 52, z: -45}, 2000)
tween3.start()

var tween4 = new TWEEN.Tween(gimbal2.position).to({x: 75, y: 52, z: 45}, 2000)
tween4.start()

var tween5 = new TWEEN.Tween(gyro1.position).to({x: 0, y: 0, z: 0}, 2000)
tween5.start()

var tween6 = new TWEEN.Tween(gyro2.position).to({x: 0, y: 0, z: 0}, 2000)
tween6.start()



var txt = new THREE.Object3D();
loadOBJWithMTL('models','/ord.obj', '/ord.mtl', object => {
  txt.add(object);
});
txt.rotation.x = -PI/2;
txt.rotation.z = PI/6;
txt.position.y = 100;
txt.position.x = -50;
txt.position.z = -100;
//scene.add(txt);

var tween7 = new TWEEN.Tween(txt.position).to({x: 0, y: 1000, z: 0}, 1000)



var camera_explode = new TWEEN.Tween(camera.position).to({x: 150, y: 260, z: 0}, 200)
var gimbal1_explode = new TWEEN.Tween(gimbal1.position).to({x: 75, y: 52, z: -75}, 1000)
var gimbal2_explode = new TWEEN.Tween(gimbal2.position).to({x: 75, y: 52, z: 75}, 1000)
var gyro1_explode = new TWEEN.Tween(gyro1.position).to({x: 60, y: 0, z: 0}, 1000)
var gyro2_explode = new TWEEN.Tween(gyro2.position).to({x: 60, y: 0, z: 0}, 1000)

var gimbal1_exploderev = new TWEEN.Tween(gimbal1.position).to({x: 75, y: 52, z: -45}, 1000)
var gimbal2_exploderev = new TWEEN.Tween(gimbal2.position).to({x: 75, y: 52, z: 45}, 1000)
var gyro1_exploderev = new TWEEN.Tween(gyro1.position).to({x: 0, y: 0, z: 0}, 1000)
var gyro2_exploderev = new TWEEN.Tween(gyro2.position).to({x: 0, y: 0, z: 0}, 1000)


var axisI = new THREE.AxisHelper(30);
var axis1 = new THREE.AxisHelper(30);
var axis2 = new THREE.AxisHelper(30);
var axis3 = new THREE.AxisHelper(30);
var axis4 = new THREE.AxisHelper(30);
var axis5 = new THREE.AxisHelper(30);


axisI.position.y = 50;
axisI.position.x = -70;
axisI.rotation.y = PI/2;

axis1.position.y = 50;
axis1.rotation.y = PI/2;


axis2.position.set(0,90,-75);
axis3.position.set(0,90,75);
axis2.rotation.y = PI/2;
axis3.rotation.y = PI/2;

axis4.position.set(0,90,-135);
axis5.position.set(0,90,135);
axis4.rotation.y = PI/2;
axis5.rotation.y = PI/2;

var k = 0;
explodedView.on('change', () => {
  k++;
  txt.position.y = 1000;
  if(k == 1){
    camera_explode.start()
    gimbal1_explode.start()
    gimbal2_explode.start()
    gyro1_explode.start()
    gyro2_explode.start()
    params.reset = true;


    scene.add(axisI);
    scene.add(axis1);
    scene.add(axis2);
    scene.add(axis3);
    scene.add(axis4);
    scene.add(axis5);
  }
  else if(k == 2){
    gimbal1_exploderev.start()
    gimbal2_exploderev.start()
    gyro1_exploderev.start()
    gyro2_exploderev.start()
    k = 0;
    params.reset = false;

    scene.remove(axisI);
    scene.remove(axis1);
    scene.remove(axis2);
    scene.remove(axis3);
    scene.remove(axis4);
    scene.remove(axis5);

  }
  
})



//-------------------GRASS---------------------

const vertexShader = `
  varying vec2 vUv;
  uniform float time;
  
    void main() {
  
    vUv = uv;
    
    // VERTEX POSITION
    
    vec4 mvPosition = vec4( position, 1.0 );
    #ifdef USE_INSTANCING
      mvPosition = instanceMatrix * mvPosition;
    #endif
    
    // DISPLACEMENT
    
    // here the displacement is made stronger on the blades tips.
    float dispPower = 1.0 - cos( uv.y * 3.1416 / 2.0 );
    
    float displacement = sin( mvPosition.z + time * 10.0 ) * ( 0.1 * dispPower );
    mvPosition.z += displacement;
    
    //
    
    vec4 modelViewPosition = modelViewMatrix * mvPosition;
    gl_Position = projectionMatrix * modelViewPosition;
  
    }
  `;
  
  const fragmentShader = `
  varying vec2 vUv;
  
  void main() {
    vec3 baseColor = vec3( 0.41, 1.0, 0.5 );
    float clarity = ( vUv.y * 0.5 ) + 0.5;
    gl_FragColor = vec4( baseColor * clarity, 1 );
  }
  `;
  
  const uniforms = {
    time: {
    value: 0
  }
  }
  
  const leavesMaterial = new THREE.ShaderMaterial({
    vertexShader,
  fragmentShader,
  uniforms,
  side: THREE.DoubleSide
  });
  
  /////////
  // MESH
  /////////
  
  const instanceNumber = 12000;
  const dummy = new THREE.Object3D();
  
  const geometry7 = new THREE.PlaneGeometry( 0.1, 1, 1, 4 );
  geometry7.translate( 0, 0.5, 0 ); // move grass blade geometry lowest point at 0.
  
  const instancedMesh = new THREE.InstancedMesh( geometry7, leavesMaterial, instanceNumber );
  instancedMesh.scale.set(20,20,20);
  instancedMesh.position.set(0,10,-600);
  scene.add( instancedMesh );
  
  // Position and scale the grass blade instances randomly.
  
  for ( let i=0 ; i<instanceNumber ; i++ ) {
  
    dummy.position.set(
    ( Math.random() - 0.5 ) * 300,
    0,
    ( Math.random() - 0.5 ) * 10
  );
  
  dummy.scale.setScalar( 0.5 + Math.random() * 0.6 );
  
  dummy.rotation.y = Math.random() * Math.PI;
  
  dummy.updateMatrix();
  instancedMesh.setMatrixAt( i, dummy.matrix );
  
  }
  const instancedMesh1 = new THREE.InstancedMesh( geometry7, leavesMaterial, instanceNumber );
  instancedMesh1.scale.set(20,20,20);
  instancedMesh1.position.set(0,10,600);
  scene.add( instancedMesh1 );
  instancedMesh1.position.set(0,10,600);
  for ( let i=0 ; i<instanceNumber ; i++ ) {
  
    dummy.position.set(
    ( Math.random() - 0.5 ) * 300,
    0,
    ( Math.random() - 0.5 ) * 10
  );
  
  dummy.scale.setScalar( 0.5 + Math.random() * 0.6 );
  
  dummy.rotation.y = Math.random() * Math.PI;
  
  dummy.updateMatrix();
  instancedMesh1.setMatrixAt( i, dummy.matrix );
  
  }
animate();

function animate() {
    if(!params.cameraAngle){
      TWEEN.update();
    }

    requestAnimationFrame(animate);


    R1_M.set(
      R1[i][0], R1[i][1], R1[i][2], 0,
      R1[i][3], R1[i][4], R1[i][5], 0,
      R1[i][6], R1[i][7], R1[i][8], 0,
      0, 0, 0, 1);

    R_transform.multiplyMatrices(transform, R1_M);
    R.multiplyMatrices(R_transform, transformrev);

    car.rotation.setFromRotationMatrix(R);
    


    gimbal1.rotation.x = gimbal[i][0];
    gimbal2.rotation.x = gimbal[i][1];
    params.pitchAngVel = o2[i][0]; 
    params.yawAngVel = o3[i][0];

    if(params.Case == 'Both Motors'){
      gyro1.rotation.y += 1;
      gyro2.rotation.y += -1;
      
    }
    else if(params.Case == 'Motor 1'){
      gyro1.rotation.y += 1;
      gyro2.rotation.y += -0;
    }
    else if(params.Case == 'Motor 2'){
      gyro1.rotation.y += 0;
      gyro2.rotation.y += -1;
    }
    
    
    //motor1.rotation.x += -0.01;
    controls.update();
    renderer.render(scene, camera);


    if(params.reset) {
      params.simSpeed = false;
      i = 0;
    }

    i += params.simSpeed;


    if(params.Case == 'Both Motors'){
      if( i>(1950) ) {
        i = 0;
      }
    }
    else if(params.Case == 'Motor 1' || params.Case == 'Motor 2' ){
      if( i>(1200) ) {
        i = 0;
      }
    }


}


function loadOBJWithMTL(path, objFile, mtlFile, onLoad) {
  const mtlLoader = new THREE.MTLLoader();
  mtlLoader.setPath(path);
  mtlLoader.load(mtlFile, materials => {
    materials.preload();
    const objLoader = new THREE.OBJLoader();
    objLoader.setMaterials(materials);
    objLoader.setPath(path);
    objLoader.load(objFile, object => {
      onLoad(object);
    });
  });
}


const canvas = renderer.domElement;

window.addEventListener( 'resize', onWindowResize, false );

		function onWindowResize(){
		
			camera.aspect = window.innerWidth / window.innerHeight;
			camera.updateProjectionMatrix();
		
			renderer.setSize( window.innerWidth, window.innerHeight );
		
		}

    var render = function () {
			requestAnimationFrame(render); //render function is called every frame
			renderer.render(scene, camera); //We need this in the loop to actually perform the rendering
		};
	
		render(); //Calls the render function


// Add event listeners for mouse events on the canvas element

var j = 0;

canvas.addEventListener('contextmenu', onRightClick, false);

// Set the initial target position and offset
var targetPosition = new THREE.Vector3(0, 50, 250);





//THIS IS THE RIGHT CLICK FUNCTION

function onRightClick(event) {
  event.preventDefault();
  
  if (j >= 3){
    j = 0;
  }

  params.simSpeed = 5;
  i = 0;
  
  
  if (j == 0) {
    R1 = R1_both();
    gimbal = gim_both();
    o2 = o2_both();
    o3 = o3_both();
    targetPosition = new THREE.Vector3(50, 100, 250);
    params.Case = 'Both Motors';
    tween7.start()
  }
  else if (j == 1) {
    R1 = R1_M1();
    gimbal = gim_M1();
    o2 = o2_M1();
    o3 = o3_M1();
    targetPosition = new THREE.Vector3(200, 100, 0);
    params.Case = 'Motor 1';
  }
  else if (j == 2) {
    R1 = R1_M2();
    gimbal = gim_M2();
    o2 = o2_M2();
    o3 = o3_M2();
    targetPosition = new THREE.Vector3(10, 200, 0);
    params.Case = 'Motor 2';

  }
  j++;
  // Zoom in on the target position
  var tween = new TWEEN.Tween(camera.position).to({x: targetPosition.x, y: targetPosition.y, z: targetPosition.z}, 500)
  tween.start()
  
}









});
