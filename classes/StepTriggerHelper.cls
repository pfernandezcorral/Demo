public without sharing class StepTriggerHelper {

	public static final String SUFIX = ' step';
    private static Map<String,Step__c> nextStepMap = new Map<String,Step__c>();
	private static List<Deployment_History__c> history = new List<Deployment_History__c>();

	public static Boolean isFeatureEnabled(Step__c s){
		Boolean res = true;
		String feature = s.Type__c + StepTriggerHelper.SUFIX;
		Feature__c f = Feature__c.getValues(feature);
		if(f != null && f.Enabled__c == false)res = false;
		System.debug('***** Checking feature: ' + feature + ': ' + res);
		return res;
	}

    public static void prepareData (List<Step__c> steps) {
        //Loads a Map with the next Step of the  current Step, based on Deployment Id and Step Order
        Set<Id> deploymentIds = new Set<Id>();
        for (Step__c step: steps) {
            deploymentIds.add(step.Deployment__c);
        }
        List<Step__c> allSteps = [SELECT Id, Status__c, Deployment__c, Name, Type__c, dataJson__c, Manual_Task_Notified__c FROM Step__c WHERE Deployment__c IN :deploymentIds ORDER BY Deployment__c, Order__c ASC];
        for (Integer i=0; i<allSteps.size(); i++) {
            if (i == allSteps.size()-1) {
                break;
            }
            else {
                nextStepMap.put('' + allSteps[i].Deployment__c + allSteps[i].Id, allSteps[i+1]);
            }
        }
    }
    
    public static void addHistory(Step__c d, String event){
        Deployment_History__c h = new Deployment_History__c(Deployment_Id__c = d.Deployment__c, Deployment__c = d.Deployment__c,Date__c= System.now(), Event__c=event, Object__c='Step', User__c=UserInfo.getUserId(), Field__c='Name');
        if(event =='Created')h.New_Value__c = d.Name;
        if(event =='Deleted')h.Old_Value__c = d.Name;
        history.add(h);
    }
    public static void addHistory(Step__c oldd, Step__c newd){
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Step__c.fields.getMap();
        for(String field:fieldMap.keyset()){
            DescribeFieldResult dfr = fieldMap.get(field).getDescribe();
            if(dfr.isUpdateable()){
                if(oldd.get(field) != newd.get(field)){
        			history.add(new Deployment_History__c(Deployment__c = oldd.Deployment__c,
                                                          Deployment_Id__c = oldd.Deployment__c,
                                                          Date__c= System.now(), 
                                                          Event__c='Updated', 
                                                          Object__c='Step', 
                                                          Field__c=dfr.getLabel(), 
                                                          User__c=UserInfo.getUserId(),
                                                          New_Value__c = (newd.get(field)!=null?String.valueOf(newd.get(field)).left(255):null),
                                                          Old_Value__c = (oldd.get(field)!=null?String.valueOf(oldd.get(field)).left(255):null)
                                                         ));            
                }
            }
        }
        
    }
    public static void insertHistory(){
        insert history;
        history.clear();
    }

    public static void notifyTaskOwner(Step__c step) {

        ManualTaskJSONdata taskData = (ManualTaskJSONdata) JSON.deserialize(step.dataJson__c, ManualTaskJSONdata.class);
        String chatterMessage = ' ' + System.Label.MANUAL_TASK_WAITING + ' ' + step.Name;
        if (String.isNotEmpty(taskData.Task_Owner)) {
            if (taskData.Notify_Task_Owner == 'Chatter' && Utilities.isChatterEnabled(Settings.ns+'Deployment__c')) {
                Utilities.notifyUsingChatterWithAtMention(taskData.Task_Owner, chatterMessage, step.Deployment__c);
            } else if (taskData.Notify_Task_Owner == 'Email') {
                notifyUsingEmail(taskData.Task_Owner, step.Name, step.Deployment__c);

            } else if (taskData.Notify_Task_Owner == 'Chatter and Email') {
                if (Utilities.isChatterEnabled(Settings.ns+'Deployment__c')) {
                    Utilities.notifyUsingChatterWithAtMention(taskData.Task_Owner, chatterMessage, step.Deployment__c);
                }
                notifyUsingEmail(taskData.Task_Owner, step.Name, step.Deployment__c);
            }
        }
    }

    public static void notifyNextOrCurrentStepOwner(Step__c currentStep) {

        if (currentStep.Status__c == 'Completed Successfully' && !currentStep.Manual_Task_Notified__c) {
            currentStep.Manual_Task_Notified__c = true;
            if (nextStepMap.containsKey('' + currentStep.Deployment__c + currentStep.Id)) {
                Step__c nextStep = nextStepMap.get('' + currentStep.Deployment__c + currentStep.Id);
                if (nextStep.Type__c == 'Manual Task' && nextStep.Status__c == 'Not started') {
                    notifyTaskOwner(nextStep);
                }
            }
        }
        else if (currentStep.Status__c == 'In Progress' && currentStep.Type__c == 'Manual Task' && currentStep.Order__c == 1 && !currentStep.Manual_Task_Notified__c) {
            notifyTaskOwner(currentStep);
        }
    }

    private static void notifyUsingEmail(String userId, String stepName, Id deploymentId) {

        User ownerOfTask = [SELECT Id,Email FROM User WHERE Id = :userId LIMIT 1];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[]{ownerOfTask.Email};
        String htmlBody = System.Label.MANUAL_TASK_WAITING + ' ' + stepName + '<br/>';
        htmlBody += 'Deployment link: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + deploymentId;
        message.setHtmlBody(htmlBody);
        message.setSubject(System.Label.MANUAL_TASK_WAITING + ' ' + stepName);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});

        if (!results[0].success) {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }
    }

    private class ManualTaskJSONdata {
        public Boolean Perform_in_Destination_Org {get;set;}
        public Boolean Perform_in_Source_Org {get;set;}
        public String Task_Description {get;set;}
        public String Task_Owner {get;set;}
        public String Notify_Task_Owner {get;set;}
    }
}