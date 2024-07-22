*** Settings ***
Resource          ./system_smoke_kw.robot

*** Variables ***
${KUBELET_VERSION}     %{KUBELET_VERSION}
${NUM_NODES}           2
${NUM_WORKERS}         1

*** Test Cases ***
Pods in kube-system are ok
    [Documentation]  Test if all pods in kube-system initiated correctly and are running or succeeded
    [Tags]    cluster    smoke
    Given kubernetes API responds
    When getting all pods names in "kube-system"
    Then all pods in "kube-system" are running or succeeded
