# This is an example test case for the Robot Framework KubeLibrary
# https://github.com/devopsspiral/KubeLibrary

*** Settings ***
Library           KubeLibrary    None

*** Variables ***
${POD_NAME_PATTERN}       my-pod-name
${NAMESPACE}              my-namespace
${IMAGE_NAME}             my-image:1.0.0
${TIMEOUT}                2min
${RETRY_INTERVAL}         5sec

*** Test Cases ***
Pods are running with correct image
    Given waited for pods matching "${POD_NAME_PATTERN}" in namespace "${NAMESPACE}" to be running
    When getting pods matching "${POD_NAME_PATTERN}" in namespace "${NAMESPACE}"
    Then all pods containers are using "${IMAGE_NAME}" image

*** Keywords ***
waited for pods matching "${POD_NAME_PATTERN}" in namespace "${NAMESPACE}" to be running
    Wait Until Keyword Succeeds    ${TIMEOUT}    ${RETRY_INTERVAL}
    ...  pod "${POD_NAME_PATTERN}" status in namespace "${NAMESPACE}" is running

pod "${POD_NAME_PATTERN}" status in namespace "${NAMESPACE}" is running
    @{namespace_pods}=    Get Pod Names in Namespace  ${POD_NAME_PATTERN}    ${NAMESPACE}
    ${num_of_pods}=    Get Length    ${namespace_pods}
    Should Be True    ${num_of_pods} >= 1    No pods matching "${POD_NAME_PATTERN}" found
    FOR    ${pod}    IN    @{namespace_pods}
        ${status}=    Get Pod Status in Namespace    ${pod}    ${NAMESPACE}
        Should Be True     '${status}'=='Running'
    END

getting pods matching "${POD_NAME_PATTERN}" in namespace "${NAMESPACE}"
    @{namespace_pods}=    Get Pods in Namespace  ${POD_NAME_PATTERN}    ${NAMESPACE}
    Set Test Variable    ${namespace_pods}

all pods containers are using "${container_image}" image
    @{containers}=    Filter Pods Containers By Name    ${namespace_pods}    .*
    @{containers_images}=    Filter Containers Images    ${containers}
    FOR    ${item}    IN    @{containers_images}
        Should Be Equal As Strings    ${item}    ${container_image}
    END
