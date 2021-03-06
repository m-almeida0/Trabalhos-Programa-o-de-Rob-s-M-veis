function sysCall_init() 
    laserHandle=sim.getObjectHandle("LaserScannerLaser_2D")
    jointHandle=sim.getObjectHandle("LaserScannerJoint_2D")
    graphHandle=sim.getObjectHandle("LaserScannerGraph_2D")
    modelHandle=sim.getObjectHandle(sim.handle_self)
    objName=sim.getObjectName(modelHandle)
    communicationTube=sim.tubeOpen(0,objName..'_2D_SCANNER_DATA',1)
    
end

function sysCall_cleanup() 
    sim.resetGraph(graphHandle)
end 

function sysCall_sensing() 
    distlat0=20
    distdiag30=20
    distdiag60=20
    distfrontal=20
    distdiag120=20
    distdiag150=20
    distlat180=20
    scanningAngle=tonumber(sim.getScriptSimulationParameter(sim.handle_self,"scanningAngle"))
    if (scanningAngle==nil) then
        scanningAngle=180
        sim.setScriptSimulationParameter(sim.handle_self,"scanningAngle",scanningAngle)
    end
    if (scanningAngle<5) then
        scanningAngle=5
    end
    if (scanningAngle>180) then
        scanningAngle=180
    end
    scanningDensity=tonumber(sim.getScriptSimulationParameter(sim.handle_self,"scanningDensity"))
    if (scanningDensity==nil) then
        scanningDensity=2
        sim.setScriptSimulationParameter(sim.handle_self,"scanningDensity",scanningDensity)
    end
    if (scanningDensity<0.1) then
        scanningDensity=0.1
    end
    if (scanningDensity>5) then
        scanningDensity=5
    end
    
    sim.resetGraph(graphHandle)
    pts=scanningAngle*scanningDensity+1
    p=-scanningAngle*math.pi/360
    stepSize=math.pi/(scanningDensity*180)
    points={}
    modelInverseMatrix=simGetInvertedMatrix(sim.getObjectMatrix(modelHandle,-1))
    for i=0,pts,1 do
        sim.setJointPosition(jointHandle,p)
        p=p+stepSize
        r,dist,pt=sim.handleProximitySensor(laserHandle) -- pt is RELATIVE to te rotating laser beam!
        if r>0 then
            -- We put the RELATIVE coordinate of that point into the table that we will return:
            m=sim.getObjectMatrix(laserHandle,-1)
            pt=sim.multiplyVector(m,pt)
            pt=sim.multiplyVector(modelInverseMatrix,pt) -- after this instruction, pt will be relative to the model base!
            table.insert(points,pt[1])
            table.insert(points,pt[2])
            table.insert(points,pt[3])
            if(i==0) then
                distlat0=dist
            end
            if(i==30)then
                distdiag30=dist
            end
            if(i==60)then
                distdiag60=dist
            end
            if (i==90)then
               distfrontal=dist
            end
            if(i==120)then
                distdiag120=dist
            end
            if(i==150)then
                distdiag150=dist
            end
            if(i==180)then
                distlat180=dist
            end
        end
        sim.handleGraph(graphHandle,0.0)
    end
    sim.setFloatSignal("Laser0",distlat0)
    sim.setFloatSignal("Laser30",distdiag30)
    sim.setFloatSignal("Laser60",distdiag60)
    sim.setFloatSignal("Laser90",distfrontal)
    sim.setFloatSignal("Laser120",distdiag120)
    sim.setFloatSignal("Laser150",distdiag150)
    sim.setFloatSignal("Laser180",distlat180)

    -- Now send the data:
    if #points>0 then
        sim.tubeWrite(communicationTube,sim.packFloatTable(points))
    end
    
    -- To read the data from another script, use following instructions (in that other script):
    --
    -- INITIALIZATION PHASE:
    -- laserScannerHandle=sim.getObjectHandle("LaserScanner_2D")
    -- laserScannerObjectName=sim.getObjectName(laserScannerHandle) -- is not necessarily "LaserScanner_2D"!!!
    -- communicationTube=sim.tubeOpen(0,laserScannerObjectName..'_2D_SCANNER_DATA',1)
    --
    -- TO READ THE DATA:
    -- data=sim.tubeRead(communicationTube)
    -- if (data) then
    --     laserDetectedPoints=sim.unpackFloatTable(data)
    -- end
    --
    -- laserDetectedPoints is RELATIVE to the model base!
end 
