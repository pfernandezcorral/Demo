trigger NextJob on Deployment_Job__c (after update) {
    List<Id> ids = new List<Id>();
    Map<Id, Deployment_Job__c> mapa = new Map<Id, Deployment_Job__c>([select id, step__c, step__r.dataJson__c, step__r.deployment__c, step__r.deployment__r.Name, step__r.order__c, step__r.deployment__r.status__c, step__r.Name from Deployment_Job__c where id in:trigger.newmap.keyset()]);

    List<Id> Ldestinations = new List<Id>();
    for (Deployment_Job__c dj : trigger.new) {
        Ldestinations.add(dj.Destination_Org__c);
    }
    List<Deployment_Job__c> nexts = [select id, step__c, name, status__c, step__r.dataJson__c, step__r.deployment__c, step__r.deployment__r.Name, step__r.Order__c, Destination_Org__c, step__r.Type__c, step__r.Name from Deployment_Job__c where Destination_Org__c IN :Ldestinations];
    List<Deployment_Job__c> updatedJobs = new List<Deployment_Job__c>();

    Map<String, Deployment_Job__c> Mnexts = new Map<String, Deployment_Job__c>();

    for (Deployment_Job__c dj : nexts) {
        Mnexts.put('' + dj.Destination_Org__c + dj.status__c + String.valueOf(dj.step__r.Order__c), dj);
    }
    List<Deployment__c> updateDeployments = new List<Deployment__c>();
    Map<Id, List<Deployment_Job__c>> djToDeployment = new Map<Id, List<Deployment_Job__c>> ();
    for (Deployment_Job__c dj : trigger.new) {

        if (dj.Status__c == 'Success' && trigger.oldMap.get(dj.id).Status__c != 'Success' ||
                dj.Status__c == 'Failed' && trigger.oldMap.get(dj.id).Status__c != 'Failed'  ||
                dj.Status__c == 'Cancelled' && trigger.oldMap.get(dj.id).Status__c != 'Cancelled'
           ) {

            Deployment_Job__c next = null;
            //we DON'T try to deploy all the steps even if some fails
            if (dj.Status__c == 'Success' && trigger.oldMap.get(dj.id).Status__c != 'Success') {
                Integer nextOrder = Integer.valueOf(mapa.get(dj.id).step__r.Order__c) + 1;

                if (Mnexts.containsKey('' + dj.Destination_Org__c + 'Pending' + String.valueOf(nextOrder))) {
                    next = Mnexts.get('' + dj.Destination_Org__c + 'Pending' + String.valueOf(nextOrder));
                    //Prevent Manual Tasks from calling the backend
                    if (next.Step__r.Type__c != 'Manual Task') {
                        ids.add(next.id);
                    }
                    else {
                        next.Status__c = 'In Progress';
                        updatedJobs.add(next);
                    }
                    System.debug('@@@@@ Done with this job: ' + dj.name + ' (' + dj.status__c + ')' + ' Next one is: ' + next.name);
                }
            }
            Id deploymentId = mapa.get(dj.id).step__r.deployment__c;
            if (djToDeployment.containsKey(deploymentId)) {
                List<Deployment_Job__c> temp = djToDeployment.get(deploymentId);
                temp.add(dj);
                djToDeployment.put(deploymentId,temp);
            } else {
                List<Deployment_Job__c> temp = new List<Deployment_Job__c>();
                temp.add(dj);
                djToDeployment.put(deploymentId,temp);
            }
        }
        //Bulkified
        if (dj.Status__c == 'In progress' && mapa.get(dj.id).step__r.deployment__r.status__c != 'In progress') {
            updateDeployments.add(new Deployment__c(id = mapa.get(dj.id).step__r.deployment__c, status__c = 'In progress'));
        }
    }

    Utilities.Secure_DML(updatedJobs, Utilities.DML_Action.UPD, schema.Sobjecttype.Step__c);

    //Bulkified
    //DEFINE THE STATUS OF STEPS, DESTINATION ORGS AND DEPLOYMENT
    Map<Id, String> statuses = DeployJobHelper.updateStatus(djToDeployment);
    for(Id dId : statuses.keySet()){
        if (statuses.get(dId).startsWith('Completed') && !Test.isRunningTest()){
            DeployAPI.cleanDeploy(dId);
        }
    }


    if (ids.size() > 0) {
        DeployAPI.deployJob(ids, UserInfo.getSessionId());
    }
    if (!updateDeployments.isEmpty()) {
        Utilities.Secure_DML(updateDeployments, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);
    }

    public static boolean isChatterEnabled() {
        return Schema.SObjectType.User.isFeedEnabled() && Schema.SObjectType.Deployment__c.isFeedEnabled();
    }

    private class ManualTaskJSONdata {
        public Boolean Perform_in_Destination_Org {get;set;}
        public Boolean Perform_in_Source_Org {get;set;}
        public String Task_Description {get;set;}
        public String Task_Owner {get;set;}
        public String Notify_Task_Owner {get;set;}
    }
}