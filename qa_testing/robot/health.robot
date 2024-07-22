*** Settings ***
Library	Process
Library	Collections
Library	String
Library	OperatingSystem

*** Keywords ***
Get HR List
	${proc}=	Run Process	kubectl get hr -n batcave | grep -v NAME | cut -d' ' -f1	shell=True
	@{HRs}=	Split String	${proc.stdout}	\n
	Log	${HRs}
	RETURN	@{HRs}

Get HelmRelease State
	[Arguments]	${hr}
	${proc}=	Run Process	kubectl get hr ${hr} -n batcave -o jsonpath\='{.status.conditions[0].message}'	shell=True
	RETURN	${proc.stdout}

Get Pod States
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_pod_states_stdout.txt
	${proc}=	Run Process	kubectl get pods -A | grep -v NAME | awk '{print $2 " " $4}'	shell=True	stdout=${stdout_filename}
	@{tokens}=	Split String	${proc.stdout}
	&{POD_STATES}=	Create Dictionary	@{tokens}
	Log Many	&{POD_STATES}
	Remove File	${stdout_filename}
	RETURN	&{POD_STATES}

Get Pod Ready States
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_pod_ready_states_stdout.txt
	${proc}=	Run Process	kubectl get pods -A -o jsonpath\='{range .items[*]}{.metadata.name};{range .status.containerStatuses[*]}{.name}: Ready\={.ready} Reason\={.state.terminated.reason},{end};' | sed -E 's/;+$//'	shell=True	stdout=${stdout_filename}
	Log	${proc.stdout}
	@{tokens}=	Split String	${proc.stdout}	;
	&{POD_STATES}=	Create Dictionary	@{tokens}
	Log Many	&{POD_STATES}
	Remove File	${stdout_filename}
	RETURN	&{POD_STATES}

Get Deployments
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_get_deployments.txt
	${proc}=	Run Process	kubectl get deploy -A | grep -v NAME	shell=True	stdout=${stdout_filename}
	@{lines}=	Split To Lines	${proc.stdout}
	Remove File	${stdout_filename}
	RETURN	@{lines}

Get Stateful Sets
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_get_statefulsets.txt
	${proc}=	Run Process	kubectl get statefulset -A | grep -v NAME	shell=True	stdout=${stdout_filename}
	@{lines}=	Split To Lines	${proc.stdout}
	Remove File	${stdout_filename}
	RETURN	@{lines}

Get Daemon Sets
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_get_daemonsets.txt
	${proc}=	Run Process	kubectl get daemonset -A | grep -v NAME	shell=True	stdout=${stdout_filename}
	@{lines}=	Split To Lines	${proc.stdout}
	Remove File	${stdout_filename}
	RETURN	@{lines}

Get Nodes
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_get_nodes.txt
	${proc}=	Run Process	kubectl get nodes -A | grep -v NAME	shell=True	stdout=${stdout_filename}
	@{lines}=	Split To Lines	${proc.stdout}
	Remove File	${stdout_filename}
	RETURN	@{lines}

Get VS
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_get_virtualservices.txt
	${proc}=	Run Process	kubectl get vs -A | grep -v NAME	shell=True	stdout=${stdout_filename}
	@{lines}=	Split To Lines	${proc.stdout}
	Remove File	${stdout_filename}
	RETURN	@{lines}

Get HTTP Code
	[Arguments]	${url}
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_get_httpcode.txt
	${proc}=	Run Process	curl --max-time 5 -g -w '\%{http_code}\\n' ${url} -L -o /dev/null -s	shell=True	stdout=${stdout_filename}
	TRY
		${http_code}=	Set Variable	${proc.stdout}
	EXCEPT
	  ${http_code}=	Set Variable	000
	END
	Remove File	${stdout_filename}
	RETURN	${http_code}

Get ArgoCD Sync Status
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_get_argocd_sync_status.txt
	${proc}=	Run Process	kubectl get Applications -n argocd -o jsonpath\='{range .items[*]}{.metadata.name}{","}{.status.health.status}{","}{.status.sync.status}{"\\n"}{end}'	shell=True	stdout=${stdout_filename}
	@{lines}=	Split To Lines	${proc.stdout}
	Remove File	${stdout_filename}
	RETURN	${lines}

Get EC2 Instance Names With Group
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_get_ec2_instance_names.txt
	${proc}=	Run Process	aws ec2 describe-instances --filters "Name\=tag-key,Values\=eks:nodegroup-name" "Name\=instance-state-name,Values\=running" | jq '.Reservations[].Instances[] | [(.PrivateDnsName),(.Tags[] | select(.Key\=\="eks:nodegroup-name").Value)] | @tsv' | sort	shell=True	stdout=${stdout_filename}
	@{lines}=	Split To Lines	${proc.stdout}
	Log Many	@{lines}
	Remove File	${stdout_filename}
	RETURN	${lines}

Get Node Names With Group
	${stdout_filename}=	Set Variable	/tmp/${STDOUT_PREFIX}_get_node_names.txt
	${proc}=	Run Process	kubectl get nodes -o json | jq '.items[].metadata | [(.name), (.labels["eks.amazonaws.com/nodegroup"])] | @tsv' | sort	shell=True	stdout=${stdout_filename}
	@{lines}=	Split To Lines	${proc.stdout}
	Log Many	@{lines}
	Remove File	${stdout_filename}
	RETURN	${lines}

*** Variables ***
# expected hr list
@{EXPECTED_HRS}=	batcave	argocd	authservice	fluentbit	grafana	istio	istio-operator	jaeger	kiali	loki	metrics-server	monitoring	sonar-agent	thanos	velero	kyverno
@{GITLAB_CLUSTERS}	batcave-dev	batcave-test	batcave-prod
@{DEFECTDOJO_CLUSTERS}	batcave-dev	batcave-test	batcave-prod
@{ACCEPTABLE_RESPONSE_CODES}=	200	301	302	401	403	404	406

# Pod states considered successful
@{GOOD_POD_STATES}	Running	Completed

*** Test Cases ***
Override
# Consistent prefix for stdout
	${stdout_prefix}=	Generate Random String	20
	${STDOUT_PREFIX}=	Set Global Variable	${stdout_prefix}

All Pods Have Ready Containers
	&{POD_STATES}=	Get Pod Ready States
	Log Many	@{GOOD_POD_STATES}
	FOR	${pod_name}	IN	@{POD_STATES}
		# Check pods for ready containers, but ignore pods in "Completed" state
		Run Keyword If	'Completed' not in '${POD_STATES}[${pod_name}]'	Run Keyword And Continue On Failure	Should not contain	${POD_STATES}[${pod_name}]	Ready\=false	Pod ${pod_name} has non-ready containers
	END

# All helm releases resolved?
All HelmReleases Reconciled
	@{current_helm_releases}=	Get HR List
	FOR	${helm_release}	IN	@{current_helm_releases}
		${state}=	Get HelmRelease State	${helm_release}
		TRY
			Run Keyword And Continue On Failure	Should Contain Any	${state}	Helm upgrade succeeded	Helm install succeeded	Release reconciliation succeeded	msg=Flux HelmRelease '${helm_release}' in unexpected state: ${state}
		EXCEPT	Flux HelmRelease '*' in unexpected state: Fulfilling prerequisites*	type=GLOB
			Log	Flux HelmRelease '${helm_release} is in progress '${state}'. This may disappear on rerun. If it doesn't, check the chart state.	WARN
		END
	END

# Are the things we expect there?
All Expected HelmReleases Exist
    @{expected_hrs}=    Set Variable    ${EXPECTED_HRS}    # Creates local copy of the global list
    @{current_helm_releases}=    Get HR List

    # Add cluster-specific HelmReleases
    IF    "%{CLUSTER_NAME}" in @{GITLAB_CLUSTERS}
        Append to List    ${expected_hrs}    gitlab    gitlab-runner
        Log    Adding gitlab and gitlab-runner
    END

    IF    "%{CLUSTER_NAME}" in @{DEFECTDOJO_CLUSTERS}
        Append to List    ${expected_hrs}    defectdojo
        Log    Adding defectdojo
    END

    # Check if all expected HelmReleases exist
    FOR    ${expected}    IN    @{expected_hrs}
        Run Keyword And Continue On Failure    Should contain    ${current_helm_releases}    ${expected}    HR ${expected} not found
    END

# Anything in pending state?
No Pending Pods
	&{POD_STATES}=	Get Pod States
	Dictionary should not contain value	${POD_STATES}	Pending

# Any unhealthy pods?
All Pods Successful
	&{POD_STATES}=	Get Pod States
	Log Many	@{GOOD_POD_STATES}
	FOR	${pod_name}	IN	@{POD_STATES}
		Should be true	"${POD_STATES}[${pod_name}]" in @{GOOD_POD_STATES}	${pod_name} is not in a good state
	END

# Check that all deployments rolled out the expected number of replicas
Check Deployments
	@{DEPLOY_LINES}=	Get Deployments
	FOR	${line}	IN	@{DEPLOY_LINES}
		@{tokens}=	Split String	${line}
		${name}=	Set Variable	${tokens}[1]
		${fraction}=	Set Variable	${tokens}[2]
		@{parts}=	Split String	${fraction}	/
		Should be equal	${parts}[0]	${parts}[1]	Only ${parts}[0] of ${parts}[1] ready for ${name}	values=False
	END

# Check that all stateful sets rolled out the expected number of replicas
Check Stateful Sets
	@{SET_LINES}=	Get Stateful Sets
	FOR	${line}	IN	@{SET_LINES}
		@{tokens}=	Split String	${line}
		${name}=	Set Variable	${tokens}[1]
		${fraction}=	Set Variable	${tokens}[2]
		@{parts}=	Split String	${fraction}	/
		Should be equal	${parts}[0]	${parts}[1]	Only ${parts}[0] of ${parts}[1] ready for ${name}	values=False
	END

# Check that all daemon sets rolled out to the expected number of nodes
Check Daemon Sets
	@{SET_LINES}=	Get Daemon Sets
	FOR	${line}	IN	@{SET_LINES}
		@{tokens}=	Split String	${line}
		${name}=	Set Variable	${tokens}[1]
		${desired}=	Set Variable	${tokens}[2]
		${ready}=	Set Variable	${tokens}[4]
		${avail}=	Set Variable	${tokens}[6]
		Run Keyword And Continue On Failure	Should be equal	${ready}	${desired}	Only ${ready} of ${desired} ready for ${name}	values=False
		Run Keyword And Continue On Failure	Should be equal	${avail}	${desired}	Only ${avail} of ${desired} available for ${name}	values=False
	END

# Check that all nodes are ready
Check Nodes
	@{NODE_LINES}=	Get Nodes
	FOR	${line}	IN	@{NODE_LINES}
		@{tokens}=	Split String	${line}
		${name}=	Set Variable	${tokens}[0]
		${status}=	Set Variable	${tokens}[1]
		Run Keyword And Continue On Failure	Should be equal	${status}	Ready	Node ${name} not ready	values=False
	END

# Check virtual services
Check Virtual Services
	@{ignored_vs}=	Create List	eppe-mailpit	thanos
	@{VS_LINES}=	Get VS
	FOR	${line}	IN	@{VS_LINES}
		@{tokens}=	Split String	${line}
		${name}=	Set Variable	${tokens}[1]
		${hosts}=	Set Variable	${tokens}[3]
		@{urls}=	Split String	${hosts}	\x22
		${first_url}=	Set Variable	${urls}[1]
		${http_code}=	Get HTTP Code	${first_url}
		IF	"${name}" in @{ignored_vs}
			Log	${name} is ignored
			Continue For Loop
		END
		Run Keyword and Continue on Failure	Should be true	"${http_code}" in ${ACCEPTABLE_RESPONSE_CODES}	${name} returned ${http_code} for ${first_url}
	END

Check ArgoCD
	@{argocd_lines}=	Get ArgoCD Sync Status
	FOR	${line}	IN	@{argocd_lines}
		@{tokens}=	Split String	${line}	,
		${name}=	Set Variable	${tokens}[0]
		${health}=	Set Variable	${tokens}[1]
		${sync}=	Set Variable	${tokens}[2]
		Run Keyword and Continue on Failure	Should be equal	${health}	Healthy	${name} is not healthy
		Run Keyword and Continue on Failure	Should be equal	${sync}	Synced	${name} is not synced
	END

Check All Instances Are Nodes With Same Group
	@{nodes}=	Get Node Names With Group
	@{instances}=	Get EC2 Instance Names With Group
	Lists Should Be Equal	${nodes}	${instances}
