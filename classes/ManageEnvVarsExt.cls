public with sharing class ManageEnvVarsExt {

    public List<ManagedEnvVars> Lmenv {get;set;}
    public Set<Id> SenvIds = new Set<Id>();
    public Set<String> SenvNames = new Set<String>();
    public Boolean editing {get;set;}
    public String newEnvVarName {get;set;}
    public String deleteVarName {get;set;}
    private Id deploymentFlowId;
    public Map<String,Set<String>> existingNames = new Map<String,Set<String>>();
    public map<Id,String> envIdWithName = new map<Id,String>();
    public map<String,String> envNameWithId = new map<String,String>();
    public ManageEnvVarsExt (ApexPages.StandardController std) {
        bestPractices();
        editing = false;
        deploymentFlowId = std.getId();
    }
    
    public void editModeOn () {
        editing = true;
    }
    
    public void bestPractices () {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.ENV_VARS_VALUE_REQUIRED));
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Value for each environment should be unique'));
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.ENV_VARS_EASY_VALUES));
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.ENV_VARS_EASY_VALUES));
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.ENV_VARS_GOOD_VALUES));
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.ENV_VARS_COMMIT));
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.ENV_VARS_DEPLOY));
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.ENV_VARS_MORE + ' <a href="' + Label.ENV_VARS_DOCS + '">' + Label.ENV_VARS_DOCS + '</a>'));

    }
    
    public void createMissingVars () {
        system.debug(deploymentFlowId);
        List<Environmental_Variable__c> LevIns = new List<Environmental_Variable__c>();
        String repo;
        Set<String> Sbranches = new Set<String>();
        for (Deployment_Flow_Step__c dfs: [SELECT Source_Environment__c, Destination_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name, Branch__c, Deployment_Flow__r.Git_Repository__c
                                           FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :deploymentFlowId]) {
            SenvIds.add(dfs.Source_Environment__c);
            SenvIds.add(dfs.Destination_Environment__c);
            SenvNames.add(dfs.Source_Environment__r.Name);
            SenvNames.add(dfs.Destination_Environment__r.Name);
            envIdWithName.put(dfs.Source_Environment__c, dfs.Source_Environment__r.Name);
            envIdWithName.put(dfs.Destination_Environment__c, dfs.Destination_Environment__r.Name);
            envNameWithId.put(dfs.Source_Environment__r.Name,dfs.Source_Environment__c);
            envNameWithId.put(dfs.Destination_Environment__r.Name,dfs.Destination_Environment__c);

            Sbranches.add(dfs.Branch__c);
            repo = dfs.Deployment_Flow__r.Git_Repository__c;
        }
        
        for (Continuous_Integration__c ci : [SELECT Destination_Org_Credential__r.Environment__c, Destination_Org_Credential__r.Environment__r.Name 
                                             FROM Continuous_Integration__c WHERE Branch__c IN :Sbranches AND Git_Repository__c = :repo]) {
        	SenvIds.add(ci.Destination_Org_Credential__r.Environment__c);
            SenvNames.add(ci.Destination_Org_Credential__r.Environment__r.Name + ' - CI');
            envIdWithName.put(ci.Destination_Org_Credential__r.Environment__c, ci.Destination_Org_Credential__r.Environment__r.Name);
            envNameWithId.put(ci.Destination_Org_Credential__r.Environment__r.Name,ci.Destination_Org_Credential__r.Environment__c);

        }
        system.debug(SenvIds);
        Boolean missingVariables = false;
        map<String,Environmental_Variable__c> keyWithEV = new map<String,Environmental_Variable__c>();
        
        set<String> evName = new set<String>();
        list<String> evNameList = new list<String>();
        List<Environmental_Variable__c> Lev = [SELECT Environment__c, Id, Name, Value__c, Environment__r.Name FROM Environmental_Variable__c WHERE Environment__c IN :SenvIds ORDER BY Name];

        for (Environmental_Variable__c ev :Lev) {
            evName.add(ev.Name);                   
            keyWithEV.put(ev.Name+'.'+ev.Environment__r.Name, ev);
            
        }
        evNameList.addAll(evName);
        list<string> envName = getEnvNames();
        for(integer i = 0; i<evNameList.size(); i++){
            for(integer j = 1; j<envName.size(); j++){
                if(keyWithEV.containsKey(evNameList[i]+'.'+envName[j])){
                    LevIns.add(keyWithEV.get(evNameList[i]+'.'+envName[j]));
                }else{
                    missingVariables = TRUE;
                    LevIns.add(new Environmental_Variable__c(Environment__c = envNameWithId.get(envName[j]), Name = evNameList[i]));
                }
            }
        }
        system.debug(LevIns);
        Lmenv = getEnvVars(LevIns);
        system.debug(Lmenv);
        
        //If current customers are missing a variable the will be Warned 
        if(missingVariables){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, System.LABEL.ENV_VARS_MISSING_VALS));
        }
    }
    
    public List<ManagedEnvVars> getEnvVars (List<Environmental_Variable__c> Lev) {
        
       List<ManagedEnvVars> LmenvAux = new List<ManagedEnvVars>();
        
        //List<Environmental_Variable__c> Lev = [SELECT Id, Name, Value__c, Environment__c, Environment__r.Name FROM Environmental_Variable__c WHERE Environment__c IN :SenvIds ORDER BY Name, Environment__r.Name];
        set<String> envNames = new set<String>();
        String prevName = null;
        ManagedEnvVars mev = new ManagedEnvVars();
        mev.LmanagedEnvVar = new List<Environmental_Variable__c>();
        for (Environmental_Variable__c ev :Lev) {
            system.debug(ev);
            if (prevName != ev.Name && prevName != null) {                
                mev = new ManagedEnvVars();
                mev.LmanagedEnvVar = new List<Environmental_Variable__c>();
                mev.meName = ev.Name;                
                mev.LmanagedEnvVar.add(ev);
                prevName = ev.Name;
            }else{
                mev.meName = ev.Name;
                mev.LmanagedEnvVar.add(ev);
                prevName = ev.Name;
            }
            if(!envNames.contains(ev.Name)){
                LmenvAux.add(mev);
                envNames.add(ev.Name);                    
            }
            
        }
        //LmenvAux.sort();
        system.debug(LmenvAux);
        return LmenvAux;
    }
    
	public List<String> getEnvNames () {
        List<String> Lcolumns = new List<String>();
        List<String> LcolumnsSorted = new List<String>();
        Lcolumns.add(Label.NAME);
        LcolumnsSorted.addAll(SenvNames);
        LcolumnsSorted.sort();
        Lcolumns.addAll(LcolumnsSorted);
        return Lcolumns;
    }
    
    public PageReference save () {
        try{
            //Values per Environment should be unique
            set<String> uniqueEnvNameValue = new set<String>();
            List<Environmental_Variable__c> LevUpd = new List<Environmental_Variable__c>();
            Boolean DupeFound = false;
            for (ManagedEnvVars mev :Lmenv) {
                for (Environmental_Variable__c ev :mev.LmanagedEnvVar) {
                    ev.Name = mev.meName;
                    if(!uniqueEnvNameValue.contains(ev.Value__c+ev.Environment__c)){
                        uniqueEnvNameValue.add(ev.Value__c+ev.Environment__c);
                    }else{
                        //duplicate has been found, return and show error
                        DupeFound = true;
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, String.format(System.LABEL.ENV_VARS_DUPLICATE_VAL_ENV, new String[]{ev.Value__c,envIdWithName.get(ev.Environment__c)})));
                    }
                }
                LevUpd.addAll(mev.LmanagedEnvVar);            
            }
            system.debug(uniqueEnvNameValue);
            if(DupeFound){
                //1 or more duplicate values per environment were found     
                editing = true;             
                return null;
            }else{
                system.debug('Upserting Env Variables');
                Utilities.Secure_DML(LevUpd, Utilities.DML_Action.UPS, schema.Sobjecttype.Environmental_Variable__c);                
                editing = false;                                
                return null;
            }
        }catch(Exception e){
            //Do not show FIELD_CUSTOM_VALIDATION_EXCEPTION messages
            system.debug(e.getMessage());
            if(!e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
             ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ''+e.getMessage()));
            }
        }
        return null;
        
    }
    
    public PageReference cancel(){
        editing = false;
            return null;
    }
    
    public PageReference newVar () {
        system.debug(existingNames);
        system.debug(newEnvVarName);
        if(existingNames.containsKey(newEnvVarName)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.DUPLICATED_ENVIRONMENTAL_VARIABLE));
            return null;
        }
    

        List<Environmental_Variable__c> LevTmp = new List<Environmental_Variable__c>();

        list<string> envName = getEnvNames();

        for(integer j = 1; j<envName.size(); j++){
            Environmental_Variable__c ev = new Environmental_Variable__c();
            ev.Name = newEnvVarName;
            ev.Environment__c = envNameWithId.get(envName[j]);
            ev.Value__c = null;
            LevTmp.add(ev);
        }
        try {
            //Utilities.Secure_DML(LevTmp, Utilities.DML_Action.INS, schema.Sobjecttype.Environmental_Variable__c);
            ManagedEnvVars mev = new ManagedEnvVars();
            mev.meName = newEnvVarName;
            mev.LmanagedEnvVar = new List<Environmental_Variable__c>();
            mev.LmanagedEnvVar.addAll(LevTmp);
            Lmenv.add(mev);  
            editing = true;
        }
        catch (Exception e) {
            if(!e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            }
            editing = false;
        }
        return null;
    }
    
    public PageReference doDelete () {
        //Remove Item from List
        Integer index = 0;
        for(ManagedEnvVars m : Lmenv){
            if(m.meName == deleteVarName){
                break;
            }
            index ++;
        }
        Lmenv.remove(index);
        Utilities.Secure_DML([SELECT Id FROM Environmental_Variable__c WHERE Name = :deleteVarName], Utilities.DML_Action.DEL, schema.Sobjecttype.Environmental_Variable__c);
        editing = false;
        return null;

    }
    
    public class ManagedEnvVars {
        public String meName {get;set;}
        public List<Environmental_Variable__c> LmanagedEnvVar {get;set;}
    }
}