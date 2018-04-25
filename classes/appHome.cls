public with sharing class appHome {
    
    public List<copadoTransaction> transactions;
    public List<Feature__c> features{get;set;}
    private String responseBody;
    
    public class copadoTransaction{
        public String userName {get;set;}
        public String deployment {get;set;}
        public String stepName {get;set;}
        public String job {get;set;}
        public String destinationOrg {get;set;}
        public String ddate {get;set;}
        public Integer credits {get;set;}
        public Decimal minutes {get;set;}
        public String tType{get;set;}
    }

    public appHome(){
        transactions = new List<copadoTransaction>();
        features = Feature__c.getall().values();
    }
    public List<copadoTransaction> getTransactions(){
        transactions = new List<copadoTransaction>();
        try{
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            DeployAPI.setAuthHeaders(req);//to authenticate agains heroku servers        
            req.setEndpoint(settings.Server_URL+'/?transactions=true');
            req.setMethod('GET');
            HttpResponse res = h.send(req);
            //if reponse code is 401 return;
            if(res.getStatusCode() == 401){
                system.debug('appHome.init: Unauthized');
                return null;
            }
            Map<String, Object> fullMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            Map<String, Object> userInfoMap = (Map<String, Object>)fullMap.get('userInfo');
            Map<String, Object> orgMap = (Map<String, Object>)fullMap.get('customerOrg');
            List<Object> obj_transactions = (List<Object>)fullMap.get('transactions');
            
            Set<Id> deploySet = new Set<Id>();
            Set<Id> ownerIdSet = new Set<Id>();
            
            for(Object o : obj_transactions){
                Map<String, Object> tmp = (Map<String, Object>)o;
                try{
                    if(tmp.get('deploymentId')!=null && String.isNotBlank((String)tmp.get('deploymentId'))){
                    	deploySet.add((String)tmp.get('deploymentId')); 
                    }
                    if(tmp.get('userId')!=null && String.isNotBlank((String)tmp.get('userId'))){
                    	ownerIdSet.add((String)tmp.get('userId')); 
                    }
                }
                catch(Exception eParse){
                    system.debug(eParse.getStackTraceString());
                    System.debug('error while parsing transactions: ' + eParse.getMessage());
                }
            }
            Map<Id,Deployment__c> deploymentMap = new Map<Id,Deployment__c>([select Id, Name, OwnerId from Deployment__c where Id in :deploySet limit 10000]);
            
            for(Deployment__c d : deploymentMap.values()){
                ownerIdSet.add(d.OwnerId);
            }
            Map<Id,User> userMap = new Map<Id,User>([select Id, Name from User where Id IN:ownerIdSet limit 10000]);
            Map<Id,Deployment_Job__c> jobMap = new Map<Id,Deployment_Job__c>([select Id, Name, Step__r.Name, Step__r.Deployment__c, Destination_Org__r.To_Org_Name__c from Deployment_Job__c where Step__r.Deployment__c in :deploySet limit 20000]);
            
            
            for(Object o : obj_transactions){
                Map<String, Object> tmp = (Map<String, Object>)o;
                copadoTransaction ct = new copadoTransaction();
                try {ct.userName = userMap.get((String)tmp.get('userId')).Name;}catch(Exception ex){ ct.userName = ''; }
                ct.credits = (Integer)tmp.get('credits');
                ct.minutes = (Decimal)tmp.get('minutes');
                if(ct.credits < 0 || ct.minutes <0){
                    if(ct.credits < 0)try {ct.deployment = deploymentMap.get((String)tmp.get('deploymentId')).Name;}catch(Exception ex){ ct.deployment = Label.RECORD_DELETED; }
                    if(ct.credits < 0)try {ct.job = jobMap.get((String)tmp.get('jobId')).Name;}catch(Exception ex){ ct.job = Label.RECORD_DELETED; }
                    if(ct.credits < 0)try {ct.destinationOrg = jobMap.get((String)tmp.get('jobId')).Destination_Org__r.To_Org_Name__c;}catch(Exception ex){ ct.destinationOrg = Label.RECORD_DELETED; }
                    if(ct.credits < 0)try {ct.stepName = jobMap.get((String)tmp.get('jobId')).Step__r.Name;} catch(Exception ex){ ct.stepName = Label.RECORD_DELETED; }
                	ct.ddate = (String)tmp.get('date');
                	String action = tmp.get('stepType')+'';
                    if(action !=null && (action == 'diff' || action == 'backup' || action == 'test'
                        || action == 'fileDiff' || action == 'buildTask')){
                        String descrip = action;
                        if(action == 'diff')descrip = OrgDiff__c.sObjectType.getDescribe().getLabel();
                        if(action == 'test')descrip = Apex_Test_Result__c.sObjectType.getDescribe().getLabel();
                        if(action == 'backup')descrip = Git_Backup__c.sObjectType.getDescribe().getLabel();
                        if(action == 'fileDiff')descrip = Snapshot_Difference__c.sObjectType.getDescribe().getLabel();
                        if(action == 'buildTask')descrip = Build_Task__c.sObjectType.getDescribe().getLabel();
                        ct.deployment = 'Action performed was ' + descrip;
                        ct.job = '';
                        ct.destinationOrg = '';
                        ct.stepName = ''; 
                    }
                    if(ct.minutes <0){
                        ct.deployment = 'Action performed was Selenium Testing';
                        ct.job = '';
                        ct.destinationOrg = '';
                        ct.stepName = ''; 
                    }
                    transactions.add(ct);
                }
            }
        }
        catch(Exception e){
            system.debug(e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, ''+e.getMessage()));
        }
        return transactions;
    }
    public void syncFeatures(){
        DeployAPI.syncFeaturesNow();
        features = Feature__c.getall().values();
    }
    public void createAPIKey(){
        try{
            responseBody = DeployAPI.createAPIKeys();
        }
        catch(Exception e){
            system.debug(e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, ''+e.getMessage()));
        }
        
    }
    public void updatePrivateSettings(){
        Map<String, Object> mapa = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        String key = (String)mapa.get('api_key');
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        ps.API_Key__c = DeployAPI.encryptAPIKey(key);
        Utilities.Secure_DML(ps, Utilities.DML_Action.UPS, schema.Sobjecttype.Personal_Settings__c);
    }
    public String getAPIKey(){
        return DeployAPI.getUserAPIKey();
    }
}