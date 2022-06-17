function sysCall_init() 
    motorLeft=sim.getObjectHandle("Pioneer_p3dx_leftMotor")
    motorRight=sim.getObjectHandle("Pioneer_p3dx_rightMotor")
    
    robot = sim.getObjectHandle("Pioneer_p3dx")
    gps = sim.getObjectHandle("GPS")
    
    laserScannerHandle=sim.getObjectHandle("LaserScanner_2D")
    laserScannerObjectName=sim.getObjectName(laserScannerHandle)
    communicationTube=sim.tubeOpen(0,laserScannerObjectName..'_2D_SCANNER_DATA',1)
    
    v0=2
    erro_angulo = 0.5
    erroPos = 0.3
    state = 0
    direc = 0
    
    simulationTimer=0.0
    simulationTimeMS=0.0
    simulationTime=0.0
    aux1 = -1
    aux2 = -0.2
end

function sysCall_cleanup() 
 
end 

function module(number)
    --eu nao encontrei em lugar algum como calcular o modulo de um numero em lua
    --e modulos sao necessarios para esse codigo, entao eu criei essa funcao
    if(number>0)then
        return number
    else
        return -number
    end
end

function obstacle_detect()
    if(dis90)and(dis90<0.8)then
        return 1
    end
    if(dis120)and(dis120<0.7) then
        return 1
    end
    if(dis60)and(dis60<0.7) then
        return 1
    end
    if(dis150)and(dis150<0.6) then
        return 1
    end
    if(dis30)and(dis30<0.6) then
        return 1
    end
    return 0
end

function changedir(direc, dis90, dis60, dis120, dis30, dis150, dis0, dis180)
    if(direc==1)then
        --curva a direita/obstaculo a esquerda
        if(dis90)and(dis90<0.7)then
            vRight = -(vRight+5*(1-dis90))
            vLeft = (vLeft+5*(1-dis90))
            
        end
        if(dis120)and(dis120<0.6)then
            vRight = -(vRight+5*(1-dis120))
            vLeft = (vLeft+5*(1-dis120))
        end
        if(dis150)and(dis150<0.5)then
            vRight = -(vRight+5*(1-dis150))
            vLeft = (vLeft+5*(1-dis150))
        end
        if(dis180)and(dis180<0.4)then
            vRight = vRight-0.7
            vLeft = vLeft+0.7
        end
    end
    if(direc==-1)then
        --curva a esquerda/obstaculo a direita
        if(dis90)and(dis90<0.7)then
            vRight = (vRight+5*(1-dis90))
            vLeft = -(vLeft+5*(1-dis90))
        end
        if(dis60)and(dis60<0.6)then
            vRight = (vRight+5*(1-dis60))
            vLeft = -(vLeft+5*(1-dis60))
        end
        if(dis30)and(dis30<0.5)then
            vRight = (vRight+5*(1-dis30))
            vLeft = -(vLeft+5*(1-dis30))
        end
        if(dis0)and(dis0<0.4)then
            vRight = vRight+0.7
            vLeft = vLeft-0.7
        end
    end
    
    if(vRight~=2)then
        sin_baliz = 1
    end
    
end

function get_rand_ang()
    local auxiliar = (math.random(simulationTime-simulationTime%1)*10%6)+1
    return 30*(auxiliar-auxiliar%1)
end

function orient_dif()
    dif = 0
    if(posDestX)and(posDestY)then
        dX = posDestX-posX 
        dY = posDestY-posY
        sen = dY/math.sqrt(dY*dY+dX*dX)
        ang = math.asin(sen)
        dif = ang-angeu[3]
    end
    return dif
end

function sysCall_actuation()
    --Estados:
    --  0:"Siga em linha reta ate o destino"
    --  1:"desvie de obstaculos e siga a parede"
    --  2"vire 90 graus na direcao oposta ao destino, voce esta preso num loop"
    simulationTimeMS=sim.getSystemTimeInMs(simulationTimer)
    simulationTime=sim.getSimulationTime()

    posX=sim.getFloatSignal('gpsX')
    posY=sim.getFloatSignal('gpsY')
    
    posDestX=sim.getFloatSignal('gpsDestX')
    posDestY=sim.getFloatSignal('gpsDestY')
    
    vLeft=v0
    vRight=v0
    if(posDestX)and(posDestY)and(posX)and(posY)then
        local distDest = math.sqrt((posDestX-posX)*(posDestX-posX)+(posDestY-posY)*(posDestY-posY))
        if(distDest <0.2)then
            vLeft = 0
            vRight = 0
        end
    end
    
    dis0 = sim.getFloatSignal("Laser0")
    dis30 = sim.getFloatSignal("Laser30")
    dis60 = sim.getFloatSignal("Laser60")
    dis90 = sim.getFloatSignal("Laser90")
    dis120 = sim.getFloatSignal("Laser120")
    dis150 = sim.getFloatSignal("Laser150")
    dis180 = sim.getFloatSignal("Laser180")
    
    angeu=sim.getObjectOrientation(robot,-1)
    angdest=sim.getObjectOrientation(gps, -1)
    diference=orient_dif()
    diference = diference*180/math.pi

    --Calcula a direcao do destino em relacao a dianteira do robo
    if(diference<0)and(module(diference)>erro_angulo)then
        angDestino = -1--ir pra esquerda
    else
        angDestino = 1--ir pra direita
    end
    
    verif = obstacle_detect()
    --se for encontrado um obstaculo, e necessario decidir pra que direcao seguir
    if(verif==1)and(state~=1)then
        state = 1
        --decide a direcao a seguir. E feio, mas foi a maneira que eu achei de fazer
        --se quem estiver vendo isso souber de uma maneira mais elegante/legivel/eficiente
        --de fazer isso, por favor, me ensine.
        if(dis120)then
            if(dis60)then
                if(dis120<dis60)then
                    direc = 1
                else
                    direc = -1
                end
            else
                direc = 1
            end
        else
            direc = 10*math.random(simulationTime-simulationTime%1)%2
        end
    end

    if(state == 0)then
        --faz o robo ajustar a direcao da sua velocidade ate ela se alinhar com a reta
        --que liga a posicao do robo ao destino
        if((simulationTime-aux1)<1)then
        
        else
            if(module(diference)>erro_angulo)then
                vRight = vRight + 0.4*angDestino
                vLeft = vLeft - 0.4*angDestino
            end
        end
    end
    
    if(state==1)then
        --esse estado pode fazer duas coisas: desviar de obstaculos, que e executado por
        --changedir, e a baliza, pra qual eu nao fiz uma funcao especifica. a baliza consiste
        --em manter uma distancia mais ou menos constante da parede a ser seguida, e so
        --acontece se o robo nao estiver ativamente desviando de obstaculo
        sin_baliz = 0 --short for "sinalizador de baliza"
        
        changedir(direc, dis90, dis60, dis120, dis30, dis150, dis0, dis180)
        if(sin_baliz==0)then
            if(direc==1)then
                if(dis180>0.4)and(dis180<1)then
                    vLeft = vLeft- 0.02
                    vRight = vRight+ 0.02
                end
                if(dis180>1.5)then
                    if(checkpoint)then
                        --print("entrou no loop! direc == +1")
                        local dist = math.sqrt((posY-checkpoint[2])*(posY-checkpoint[2])+(posX-checkpoint[1])*(posX-checkpoint[1]))
                        if(dist <1)and((simulationTime-aux1)>2)then
                            --start
                            randDesv=get_rand_ang()
                            print("state is now changed to 2, with a desv = ".. randDesv)
                            state = 2
                            --end
                        end
                        aux1 = simulationTime
                        state = 0
                    else
                        checkpoint = {posX, posY, direc}
                        --print("new checkpoint: "..checkpoint[1].." "..checkpoint[2].." "..checkpoint[3])
                        aux1 = simulationTime
                        state = 0
                    end
                end
            end--if que ve direc
            
            if(direc==-1)then
                if(dis0>0.6)and(dis0<0.8)then
                    vLeft = vLeft+ 0.02
                    vRight = vRight- 0.02
                end
                if(dis0>1.5)then
                    if(checkpoint)then
                       local dist = math.sqrt((posY-checkpoint[2])*(posY-checkpoint[2])+(posX-checkpoint[1])*(posX-checkpoint[1]))
                        if(dist <1)and((simulationTime-aux1)>2)then
                            --start
                            randDesv=get_rand_ang()
                            print("state is now changed to 2, with a desv of "..randDesv)
                            state = 2
                            --end
                        end
                        aux1 = simulationTime
                        state = 0
                    else
                        checkpoint = {posX, posY, direc}
                        aux2 = simulationTime
                        --print("new checkpoint: "..checkpoint[1].." "..checkpoint[2].." "..checkpoint[3])
                        aux1 = simulationTime
                        state = 0
                    end
                end
            end--if que ve direc
            
        end
    end
    
    
    if(state==2)then--prev_ang
        --print("state==2")
        if(module(diference-randDesv)>erro_angulo)then
                vRight = vRight - 0.2*angDestino
                vLeft = vLeft + 0.2*angDestino
            end
        if(dis90)and(dis90<1.2)then
            print("state no longer 2")
            state = 0
        end
    end
    sim.setJointTargetVelocity(motorLeft,vLeft)
    sim.setJointTargetVelocity(motorRight,vRight)
end 
