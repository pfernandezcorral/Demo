public with sharing class CopadoSetupController {
	public Copado_License__c copadoLicense {get; set;}
	public Org__c orgCredentials {get; set;}
    public Git_Backup__c gitSnapshot {get; set;}
    public Deployment_Flow__c deploymentFlow {get; set;}
    public Deployment_Flow_Step__c deploymentFlowStep {get; set;}

	public String selectedGitRepositories {get; set;}
    public String selectedDeploymentFlow {get; set;}
    public String namespace {get;set;}

    public Map<Id,Org__c> orgCredentialMap {get; set;}

	public List<Git_Backup__c> gitSnapshotList {get; set;}
    public List<Deployment_Flow_Step__c> deploymentFlowStepList {get; set;}

    public Boolean enableGitSnapshotForm {get; set;}
    public Boolean enableDeploymentFlowForm {get; set;}
    public Boolean enableDeploymentFlowStepForm {get; set;}

	public CopadoSetupController() {
        gitSnapshotList = new List<Git_Backup__c>();
        deploymentFlowStepList = new List<Deployment_Flow_Step__c>();

		orgCredentials = new Org__c();
        deploymentFlow = new Deployment_Flow__c();
        copadoLicense = new Copado_License__c();

        retrieveCopadoLicenses();

		selectedGitRepositories = '';
        selectedDeploymentFlow = '';
        namespace = Settings.ns;

        enableGitSnapshotForm = false;
        enableDeploymentFlowForm = false;
        enableDeploymentFlowStepForm = false;
    }

    // used this SOQL to check current users active licenses. variable listed on visualforce page
    public void retrieveCopadoLicenses(){
        String userName = UserInfo.getFirstName() + ' ' +  UserInfo.getLastName();
        for(Copado_License__c cl : Utilities.getCopadoLicenses(userName)){
            copadoLicense = cl;
            return;
        }
    }

	// inserting org credentials
    public void createOrgCredentials(){
		try{
			insert orgCredentials;

            // to create new org credential getting new instance to clear existing values
            orgCredentials = new Org__c();
		}
		catch (Exception e){
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.ERROR_ORG_CREDENTIAL + ' / ' + e.getMessage()));
		}
    }

    // to refresh the org credential list
    public void refreshOrgCredentialList(){
        orgCredentialMap.clear();
    }

    // retrieve all org credentials, returned boolean to render org credential panel on visualforce page
    public boolean getExistingOrgCredentials(){
        orgCredentialMap = new Map<Id,Org__c>([Select Id, Name, Org_Type__c, is_Developer_Hub_Org__c, Username__c, Environment__c, Environment__r.Name, Test_Frequency__c From Org__c WHERE CreatedById =: UserInfo.getUserId() limit 1000]);
        return orgCredentialMap.size() > 0 ? false : true;
    }

	// getting git snapshots for selected git repository
	public void getsGitSnapshots(){
		if(selectedGitRepositories == 'none'){
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.SELECT_GIT_REPOSITORY_OR_CREATE_ONE));
			return;
		}
		else {
            // retrieving the git snapshots depend on the selected git repo
            gitSnapshotList = retrieveGitSnapshots(selectedGitRepositories);
		}
	}

	// returns list of the git snapshots depend on the git repo
	public List<Git_Backup__c> retrieveGitSnapshots(Id gitRepoId){
		return [Select Id, Name, Git_Repository__c, Git_Repository__r.Name, Branch__c, Git_Snapshot_Permissions__c, Frequency__c, Org__c, Org__r.Name From Git_Backup__c Where Git_Repository__c =: gitRepoId];
	}

	// filling selectoptions with possible git repositories
	public List<SelectOption> getGitRepos() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('none','-- None --'));

		for(Git_Repository__c gr : [Select Id, Name From Git_Repository__c limit 1000]){
			options.add(new SelectOption(gr.Id,gr.Name));
		}
		return options;
	}

    // used this method to get new instance of git snapshot.
    public void openGitSnapshotForm(){
        gitSnapshot = new Git_Backup__c();
        gitSnapshot.Git_Repository__c = selectedGitRepositories; // to auto populate git repository field of the git snapshot, assigned selected git repository to the git repository field of the git snapshot
        enableGitSnapshotForm = true; // it is used at rendered attribute to show git snapshot input form
    }

    // used this method to close git snapshot form
    public void closeGitSnapshotForm(){
        gitSnapshot = new Git_Backup__c();
        enableGitSnapshotForm = false;
    }

    // inserting git snapshots
    public void createGitSnapshot(){
        try{
            if(gitSnapshot.Name == null){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.GIT_SNAPSHOT_NAME_REQUIRED));
                return;
            }
            if(gitSnapshot.Branch__c == null){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.BRANCH_FIELD_REQUIRED));
                return;
            }
            if(gitSnapshot.Git_Snapshot_Permissions__c == null){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.GIT_SNAPSHOT_PERMISSION_FIELD_REQUIRED));
                return;
            }
            if(gitSnapshot.Org__c == null){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.ORG_CREDENTIAL_FIELD_REQUIRED));
                return;
            }

            insert gitSnapshot;

            enableGitSnapshotForm = false; // it is used at rendered attribute to show git snapshot input form

            // new value added to git snapshot list. So retrieving the git snapshots depend on the selected git repo
            gitSnapshotList.clear(); // clearing the old values to fill in again
            gitSnapshotList = retrieveGitSnapshots(selectedGitRepositories);
        }
        catch (Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.ERROR_GIT_SNAPSHOT + ' / ' + e.getMessage()));
        }

    }

    // filling selectoptions with possible deployment flows
    public List<SelectOption> getDeploymentFlows() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('none','-- None --'));

        for(Deployment_Flow__c df : [Select Id, Name, Active__c From Deployment_Flow__c limit 1000]){
            options.add(new SelectOption(df.Id, df.Active__c ? df.Name + ' {Active}' : df.Name));
        }
        return options;
    }

    // getting new instance for deployment flow
    public void openDeploymentFlowForm(){
        enableDeploymentFlowForm = true;
        deploymentFlow = new Deployment_Flow__c();
        selectedDeploymentFlow = '';
    }

    // closing new deployment flow form
    public void closeDeploymentFlowForm(){
        enableDeploymentFlowForm = false;
        deploymentFlow = new Deployment_Flow__c();
    }

    // to create new git repositories getting new instance to clear existing values
    public void getsDeploymentFlowSteps(){
        if(selectedDeploymentFlow == 'none'){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.SELECT_DEPLOYMENT_FLOW_OR_CREATE_ONE));
            return;
        }
        else {
            // retrieving the deployment flow steps depend on the selected deployment flow
            deploymentFlowStepList = retrieveDeploymentFlowSteps(selectedDeploymentFlow);
        }
    }

    // returns list of the git snapshots depend on the git repo
    public List<Deployment_Flow_Step__c> retrieveDeploymentFlowSteps(Id deploymentFlowId){
        return [Select Id, Name, Deployment_Flow__c, Destination_Environment__c, Destination_Environment__r.Name, Source_Environment__c, Source_Environment__r.Name, Branch__c From Deployment_Flow_Step__c Where Deployment_Flow__c =: deploymentFlowId];
    }

    // inserting deployment flow
    public void createDeploymentFlow(){
        try{
            if(deploymentFlow.Name == null){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.DEPLOYMENT_FLOW_NAME_REQUIRED));
                return;
            }

            insert deploymentFlow;

            // assigning new git repo id to the selectedGitRepositories variable to render page correctly
            selectedDeploymentFlow = deploymentFlow.Id;

            // new deployment flow is created. deployment flow step list should be cleared.
            deploymentFlowStepList.clear();

            // to close the deployment flow creation form
            enableDeploymentFlowForm = false;
        }
        catch (Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.ERROR_DEPLOYMENT_FLOW + ' / ' + e.getMessage()));
        }
    }

    // used this method to get new instance of deployment flow step.
    public void openDeploymentFlowStepForm(){
        deploymentFlowStep = new Deployment_Flow_Step__c();
        deploymentFlowStep.Deployment_Flow__c = selectedDeploymentFlow; // to auto populate deployment flow field of the deployment flow step, assigned selected deployment flow to the deployment flow field of the deployment flow step
        enableDeploymentFlowStepForm = true; // it is used at rendered attribute to show deployment flow step input form
    }

    // closing new deployment flow step form
    public void closeDeploymentFlowStepsForm(){
        enableDeploymentFlowStepForm = false;
        deploymentFlowStep = new Deployment_Flow_Step__c();
    }

    // inserting deployment flow steps
    public void createDeploymentFlowSteps(){
        try{
            insert deploymentFlowStep;

            enableDeploymentFlowStepForm = false; // it is used at rendered attribute to show deployment flow step input form

            // new value added to deployment flow step list. So retrieving the deployment flow steps depend on the selected deployment flow
            deploymentFlowStepList.clear(); // clearing the old values to fill in again
            deploymentFlowStepList = retrieveDeploymentFlowSteps(selectedDeploymentFlow);
        }
        catch (Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.Label.ERROR_DEPLOYMENT_FLOW_STEP + ' / ' + e.getMessage()));
        }
    }

    // used this method to set oauth authenticate
    public PageReference doOauth(){
        String orgCredentialId = ApexPages.currentPage().getParameters().get('setOauth');
        return String.isNotBlank(orgCredentialId) ? Utilities.doOauth(orgCredentialMap.get(orgCredentialId)) : null;
    }

    // used this global api method to retrieve API key for current user
    public String getAPIKey(){
        return DeployAPI.getUserAPIKey();
    }
}