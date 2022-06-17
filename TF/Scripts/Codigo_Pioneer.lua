function sysCall_init()

    motorLeft=sim.getObjectHandle("Pioneer_p3dx_leftMotor")
    motorRight=sim.getObjectHandle("Pioneer_p3dx_rightMotor")

    v0=2
    vLeft=v0
    vRight=v0
    erro_angulo = 10
    erroPos = 0.3
    direc = 0

    vertice = {}
    
    mapSize = 
    ------------------------------------------------------
    g_cur = -1
    g_dest = -1

    linkedList = {}
    listsize = 0

    paths = {}
    nPaths = 0
    previousPath=-1

    stateU = 0--stateU == "estado universal". Alguns estados tem substados
end

function sysCall_cleanup()

end 

function get_dis(x1, y1, x2, y2)
    return math.sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))
end

function orient_dif(xCur, yCur, xDest, yDest)
    angRob = sim.getFloatSignal("ZCompass")
    dif = 0
    if(xCur)and(yCur)and(xDest)and(yDest)then
        dX = xDest-xCur
        dY = yDest-yCur
        sen = dY/math.sqrt(dY*dY+dX*dX)
        ang = math.asin(sen)
        dif = ang-angRob
        dif = dif*180/math.pi
    end
    return dif
end

function module(number)
    --eu nao encontrei em lugar algum uma funcao "mod" em lua, e modulos sao necessarios para esse codigo
    if(number>0)then
        return number
    else
        return -number
    end
end

function find_in_path(elemento, path)
    --o path analisado nessa funcao e paths[path]
    local size = table.getn(paths[path])
    local numeroDoVertice = paths[path][size]
    local verticeVisto = vertice[numeroDoVertice]
    local limite = table.getn(verticeVisto)--

    local aux
    for i = 5, limite, 1 do
        aux = verticeVisto[i]
        --print(g_cur.." esta sendo comparado com "..aux)
        if(g_cur==aux)then
            return true
        end
    end
    return false
end

function a_estrela(destino)
--foi estabelecida previamente uma lista encadeada e seu primeiro nodo. Aqui, novos nodos sao estabelecidos e inseridos na lista
    --tendo em vista seus diferentes pesos.
    g_prev = -1
    local auxiliar = g_cur
    local currPath = 0
    local previousPath = 0
    
    while(g_cur~=destino)do
        g_cur = linkedList[1]
        vertice[g_cur][1]=false
        currPath = linkedList[3]
        linkedList=linkedList[4]
        
        --em cada interacao do while, o elo mais na ponta da lista e retirado
        --print("eliminando a cabeca da corrente, o elo "..g_cur..". Elo eliminado anteriormente: "..g_prev)

        --g_prev diferente de -1 implica que essa nao e a primeira interacaoo do ciclo, e portanto, ja existe pelo menos 1 path.
        --Uma vez confirmada a existencia de pelo menos 1 path, essa funcao escolhe em qual path a cabeca da corrente, recem
        --eliminada, vai entrar
        if(g_prev~=-1)then
            --caso 1: o a cabeca e continua ao path atual.
            --print("veridicando se o elemento "..g_cur.." esta no path "..currPath)
            local verifCaso1 = find_in_path(g_cur, previousPath)--verifCaso1 verifica se o caso 1 e verdadeiro
            if(verifCaso1)then
                --print(g_cur.." encontrado no path "..currPath)
                --aqui adiciona-se a cabeca da corrente no final do path anterior
                currPath = previousPath
                local pathSize = table.getn(paths[currPath])
                paths[currPath][pathSize+1]=g_cur
                local aux2 = paths[currPath][pathSize+1]
            else
                --caso 2: o nodo atual nao estava conectado ao path atual. Verificar no final de cada um dos paths anteriores.
                --em retrospectiva, eu acho que daria pra limpar um pouco aqui, deixar so uma variavel de verificacao
                --print(g_cur.." nao encontrado no path "..currPath..". Procurar em paths anteriores.")
                local nPaths = table.getn(paths)
                local verifCaso2 = true --necessario porque lua nao permite uma segunda condicao no for
                local auxFindInPath --variavel auxiliar que e usada para armazenar o retorno da funcao find_in_path
                
                for i = nPaths, 1, -1 do
                    --for que navega por todos os paths
                    --print("procurando por "..g_cur.." no path "..i)
                    auxFindInPath = find_in_path(g_cur, i)--verifica se o elo atual tem uma conexao no final de qualquer um dos
                    --paths ja estabelecidos
                    if(auxFindInPath)then
                        --print(g_cur.." achado no path "..i)
                        --adicionar o elemento no final do path a ele ligado
                        currPath = i
                        local pathSize = table.getn(paths[currPath])
                        paths[currPath][pathSize+1]=g_cur
                        local aux2 = paths[currPath][pathSize+1]
                        
                        i = 0 --sai do for
                        verifCaso2 = false --marca que o caso 2 aconteceu
                    end
                end
                
                local pathSize
                local auxVertice
                local auxpath
                if(verifCaso2)then
                    --caso 3: g_cur nao e continuo ao final de nenhum dos paths anteriores, criar novo path
                    --print(g_cur.." nao achado em nenhum path anterior. Criar nova bifurcacao.")
                    local limLis = 0
                    for i = nPaths, 1, -1 do
                        --ciclo de maior magnitude. Passa por cada um dos paths.
                        pathSize = table.getn(paths[i])
                        local j = pathSize
                        while(j > 1)do--for j= pathSize , 1, -1 do--notas de bug: tentei fazer o segundo ciclo com for, nao
--deu certo, eu nao faco ideia de por que nao deu certo, e deu certo com o while

                            --segundo ciclo: busca-se uma conexao com o elemento atual em cada path                            
                            --print("j vale: "..j.." no comeco do seu ciclo.\n")
                            
                            auxpath = paths[i][j]
                            auxVertice = vertice[auxpath]
                            limLis = table.getn(auxVertice)
                            
                            for k = 5, limLis, 1 do
                                --terceiro ciclo, busca em cada um dos elementos de um path
                                --print("comparando o g_cur "..g_cur.." com o elemento "..auxVertice[k])
                                if(g_cur==auxVertice[k])then
                                    --print("MATCH! Criando novo caminho")
                                    paths[nPaths+1]={}
                                    local auxiliarFor--a variavel criada para o for nao e preservada, e precisa ser usada depois.
                                    for l = 1, j, 1 do
                                        --quarto e ultimo ciclo: busca nos elementos conectados a um nodo.
                                        paths[nPaths+1][l]=paths[i][l]
                                        auxiliarFor = l
                                    end
                                    paths[nPaths+1][auxiliarFor+1]=g_cur
                                    k = limLis+2
                                    j = -1
                                    i = -1
                                end
                            end
                            j = j-1
                        end
                    end
                end
                --apesar dos (inumeros) problemas de ter esses 4 ciclos encadeados, a chance de eles serem executados ate o final
                --e infima, e o mecanismo de saida nao e muito dispendioso para processamento.
            end
        end

--esse trecho de codigo calcula os pesos de cada um dos elos ligados ao elo eliminado nesse ciclo
        local lim2 = table.getn(vertice[g_cur])--4 + vertice[g_cur][4]
        local costs = {}
        local counter = 0
        for j = 5, lim2, 1 do
            local aux = vertice[g_cur][j]
            if(vertice[aux][1])then
                --calcula o peso de cada elo conectado a cabeca da corrente/elo atual, e que nao foi visitado ainda
                local distLoc = get_dis(vertice[g_cur][2],vertice[g_cur][3],vertice[aux][2],vertice[aux][3])
                local distDest = get_dis(vertice[g_cur][2],vertice[g_cur][3],vertice[g_dest][2],vertice[g_dest][3])
                counter = counter+1
                costs[counter] = {}
                costs[counter][1]=aux
                costs[counter][2]=distLoc+distDest
                costs[counter][3]=currPath
                --print("elo "..aux.." de peso "..costs[counter][2].." e no path "..costs[counter][3])
            end
        end

--este trecho do codigo determina as posicoes de cada um dos novos elos dentro da lista encadeada
        local temp = {}
        local currElo = {}
        local eloAnt
        for i = 1, counter, 1 do
            temp = costs[i]
            --temp e um vetor temporario que armazena os valores dos novos elos da corrente. Faz-se esse ciclo para encontrar
            --um lugar para cada elo novo
            temp[4]={}
            currElo = linkedList
            local n_achou = true
        
            while(n_achou)do
                --ciclo que compara o elo novo com os demais elementos da corrente
--              print("elo analisado:")
--              print(currElo)
                if(currElo)then
                    if(temp[2]<currElo[2])then
--                      print("achou-se um lugar para "..temp[1]..", a frente de "..currElo[1])
                        temp[4]=currElo
                        if(eloAnt)then
                            eloAnt[4]=temp
                        else
                            linkedList=temp
                        end
                        n_achou = false
                    else
                        eloAnt = currElo
                        currElo = currElo[4]
                    end
                else
                    if(eloAnt)then
--                      print(temp[1].." e a ultima da lista, atras de "..eloAnt[1])
                        eloAnt[4]=temp
                        n_achou = false
                        temp[4]=nil
                    else
--                      print(temp[1].." entrou numa lista vazia")
                        linkedList = temp
                        n_achou = false
                        temp[4]=nil
                    end
                end
            end
        end
        g_prev = g_cur
        previousPath = currPath
    end
    --retorna o caminho que chegou ate o ultimo nodo.
    return currPath
end

function sysCall_actuation()
    posX = sim.getFloatSignal('gpsX')
    posY = sim.getFloatSignal('gpsY')

    posDestX = sim.getFloatSignal('gpsDestX')
    posDestY = sim.getFloatSignal('gpsDestY')


    if(g_cur == -1)then
        local mini1 = 10000000
        local mini2 = 10000000
        for i = 1, mapSize, 1 do
            if(posDestX)and(posDestY)and(posX)and(posY)then
                local aux1 = get_dis(vertice[i][2], vertice[i][3], posX, posY)
                local aux2 = get_dis(vertice[i][2], vertice[i][3], posDestX, posDestY)
                if(aux1 < mini1)then
                    mini1 = aux1
                    g_cur = i
                end
                if(aux2 < mini2)then
                    mini2 = aux2
                    if(vertice[i][4])then
                       g_dest = i
                    end
                end
            end
        end
        if(g_cur~=-1)then
            vertice[g_cur][1]=false
            
            linkedList[1] = g_cur
            linkedList[2] = mini1+get_dis(vertice[g_cur][2], vertice[g_cur][3], posDestX, posDestY)
            linkedList[3] = 1 -- primeiro path
            linkedList[4] = nil--tail
            listsize = 1
            
            paths[1]={}
            paths[1][1]=g_cur
            nPaths = 1
            --print(paths[1])
        end
    end

    if(stateU==0)and(g_cur ~= -1)then
        rightPath = a_estrela(g_dest)

        print("    ################\nprintando os elementos do caminho"..rightPath.."\n################")
        rightPathSize = table.getn(paths[rightPath])
        for i = 1, rightPathSize, 1 do
            print("passo "..i..": "..paths[rightPath][i])
        end

        counterState1 = 1--acumula qual dos passos no path de destino o estado 1 esta tomando no momento
        stateU = 1
    end

    if(stateU==1)then
        local nextNode = paths[rightPath][counterState1]
        local nextNodX = vertice[nextNode][2]
        local nextNodY = vertice[nextNode][3]
        local angDestino = 0
        
        local dist = get_dis(posX, posY, nextNodX, nextNodY)
        if(dist > erroPos)then
            
            local angDif = orient_dif(posX, posY, nextNodX, nextNodY)
            if(module(angDif)>erro_angulo)then
                if(angDif<0)then
                    angDestino = -1--ir pra esquerda
                else
                    angDestino = 1--ir pra direita
                end

                vRight = 1.5*angDestino--vRight + 0.015*angDestino
                vLeft = -1.5*angDestino--vLeft - 0.015*angDestino

            else
                vRigh=v0
                vLeft=v0
            end
            
        else
            if(counterState1~=rightPathSize)then
                counterState1 = counterState1+1
                print("saindo do nodo "..nextNode.." para o "..paths[rightPath][counterState1])
            else
                stateU = 2
            end
        end
        
    end

    if(stateU==2)then
        local dist = get_dis(posX, posY, posDestX, posDestY)
        if(dist > 1)then
            
            local angDif = orient_dif(posX, posY, posDestX, posDestY)
            if(module(angDif)>7.5)then
                if(angDif<0)then
                    angDestino = -1--ir pra esquerda
                else
                    angDestino = 1--ir pra direita
                end
                
                vRight = 1*angDestino --vRight + 0.04*angDestino
                vLeft = -1*angDestino--vLeft - 0.04*angDestino

            else
                vRigh=v0
                vLeft=v0
            end
        else
            print("chegou ao destino")
            stateU = 3
        end

    end

    if(stateU == 3)then
        vRight=0
        vLeft=0
        --tentativa de fazer um reset. Nao deu certo.
        local dist = get_dis(posX, posY, posDestX, posDestY)
        
        --if(dist > (erroPos+0.2))then
        --    print("O ponto de destino foi modificado. Iniciando reset")
        --    g_cur = -1
        --    stateU = 0
            
        --    for i = 1, mapSize, 1 do 
        --        vertice[1]=true
        --        vertice[3]=true
        --    end
        --end
    end

    --for i=1,16,1 do
    --    res,dist=sim.readProximitySensor(usensors[i])
    --    if (res>0) and (dist<noDetectionDist) then
    --        if (dist<maxDetectionDist) then
    --            dist=maxDetectionDist
    --        end
    --        detect[i]=1-((dist-maxDetectionDist)/(noDetectionDist-maxDetectionDist))
    --    else
    --        detect[i]=0
    --    end
    --end

    --vLeft=v0
    --vRight=v0
    --for i=1,16,1 do
    --    vLeft=vLeft+braitenbergL[i]*detect[i]
    --    vRight=vRight+braitenbergR[i]*detect[i]
    --end

    sim.setJointTargetVelocity(motorLeft,vLeft)
    sim.setJointTargetVelocity(motorRight,vRight)
end 
