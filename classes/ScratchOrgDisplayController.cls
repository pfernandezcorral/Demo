/**
 * Created by mertyalti on 07/02/2018.
 */

public with sharing class ScratchOrgDisplayController{
    public String scratchOrgId {get;set{
        if(value != null){
            scratchOrgId = value;
            showDisplay = true;
            showDisplayButton = true;
            showOwnerOperations = true;

            for(Org__c org: [Select OwnerId, CreatedById From Org__c Where Id =: scratchOrgId]){
                showPassword = org.OwnerId == UserInfo.getUserId() && org.CreatedById == UserInfo.getUserId() ? true : false;
                showOwnerOperations = org.OwnerId == UserInfo.getUserId() && org.CreatedById == UserInfo.getUserId() ? true : false;
                showPasswordButton = org.OwnerId == UserInfo.getUserId() && org.CreatedById == UserInfo.getUserId() ? true : false;
            }

            System.debug(LoggingLevel.INFO,'***scratchOrgId :'+scratchOrgId);
            orgDisplay = new SfdxAPIHelper.sfdxOrgDisplay();
            try{
                Attachment displayAtt = [SELECT Id,Body,Name FROM Attachment WHERE ParentId = : scratchOrgId AND Name = 'OrgDetails'];
                if(displayAtt != null){
                    System.debug(LoggingLevel.INFO,'***att.Body.toString() :'+displayAtt.Body.toString());
                    Map<String,Object> resultParser = (Map<String,Object>)JSON.deserializeUntyped(DeployAPI.decryptAPIKey(displayAtt.Body.toString()));

                    //orgDisplay.clientId = String.valueOf(resultParser.get('clientId'));
                    orgDisplay.accessToken = String.valueOf(resultParser.get('accessToken'));
                    orgDisplay.connectedStatus = [SELECT Id,Scratch_Org_Status__c FROM Org__c WHERE Id=:scratchOrgId LIMIT 1].Scratch_Org_Status__c;//String.valueOf(resultParser.get('connectedStatus'));
                    orgDisplay.id = String.valueOf(resultParser.get('id'));
                    orgDisplay.username = String.valueOf(resultParser.get('username'));
                    orgDisplay.instanceUrl = String.valueOf(resultParser.get('instanceUrl'));
                    orgDisplay.accessToken = 'SESSION ID REMOVED';
                    showDisplayButton = false;
                }
            System.debug(LoggingLevel.INFO,'***orgDisplay :'+orgDisplay);
            } catch(Exception e){
                System.debug(LoggingLevel.INFO,'***scratchOrgId::setter:exception :'+e.getMessage());
                showDisplay = false;
            }

            try{
                Attachment ideAtt = [SELECT Id,Body,Name FROM Attachment WHERE ParentId = : scratchOrgId AND Name = 'IdeDetails'];
                System.debug('**f**ideAtt : ' + ideAtt);
                if(ideAtt != null){
                    System.debug('**f**ideAtt.Body.toString() : ' + ideAtt.Body.toString());
                    System.debug('**f**DeployAPI.decryptAPIKey(ideAtt.Body.toString()) : ' + DeployAPI.decryptAPIKey(ideAtt.Body.toString()));
                    Map<String,Object> resultParser = (Map<String,Object>)JSON.deserializeUntyped(DeployAPI.decryptAPIKey(ideAtt.Body.toString()));
                    orgDisplay.password = String.valueOf(resultParser.get('password'));
                    showPasswordButton = false;
                    showDisplay = true;
                }
            } catch(Exception e){
                System.debug(LoggingLevel.INFO,'***scratchOrgId::setter:exception :'+e.getMessage());
                showPassword = false;
            }

            try{
                Attachment errorAtt = [SELECT Id,Body,Name FROM Attachment WHERE ParentId = : scratchOrgId AND Name = 'DxLoadMetadataError'];
                if(errorAtt != null){
                    showErrorButton = true;
                }
            } catch(Exception e){
                System.debug(LoggingLevel.INFO,'***scratchOrgId::setter:exception :'+e.getMessage());
                showErrorButton = false;
            }
        }
    }}

    public PageReference deleteScratchOrg(){
        SfdxAPI.orgDelete(scratchOrgId);
        return null;
    }

    public PageReference orgDetails(){
        SfdxAPI.orgDisplay(scratchOrgId);
        return null;
    }

    public PageReference generatePassword(){
        SfdxAPI.generatePassword(scratchOrgId);
        return null;
    }

    public SfdxAPIHelper.sfdxOrgDisplay orgDisplay {get;set;}
    public Boolean showDisplay {get;set;}
    public Boolean showDisplayButton {get;set;}
    public Boolean showPassword {get;set;}
    public Boolean showPasswordButton {get;set;}
    public Boolean showErrorButton {get;set;}
    public Boolean showOwnerOperations {get;set;}
}