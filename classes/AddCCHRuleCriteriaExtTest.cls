@isTest
public with sharing class AddCCHRuleCriteriaExtTest {
    @testSetup static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
    }

    @isTest static void testFull(){
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        String ns = '';
        if([select id,name, namespacePrefix from apexclass where name='CopadoSetupController' and namespaceprefix='copado'].size()==1){
            ns = 'copado__';
        }

        Compliance_Rule__c rule = new Compliance_Rule__c();
        rule.Active__c = true;
        rule.Action__c = Schema.getGlobalDescribe().get(ns+'Compliance_Rule__c').getDescribe().fields.getMap().get(ns+'Action__c').getDescribe().getPicklistValues()[0].getValue();
        rule.Error_Message__c = 'test error message';
        rule.Matching_Criteria__c = 'Equals';
        rule.Record_Count__c = 1;
        rule.Record_Count_Criteria__c = 'Number of groups';
        rule.RecordTypeId = Schema.SObjectType.Compliance_Rule__c.getRecordTypeInfosByName().get('Copado').getRecordTypeId();
        rule.Risk_Details__c = 'test risk details';
        rule.Severity__c = 'Low';
        insert rule;
        System.assertNotEquals(null,rule.Id);

        String b = '[{"categoryType":"Profile","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"applicationVisibilities","metadataType":"applicationVisibility","metadataNameField":"application","fields":["application:string","default:boolean","visible:boolean"]},{"name":"classAccesses","metadataType":"classAccess","metadataNameField":"apexClass","fields":["apexClass:string","enabled:boolean"]},{"name":"customPermissions","metadataType":"customPermission","metadataNameField":"name","fields":["enabled:boolean","name:string"]},{"name":"externalDataSourceAccesses","metadataType":"externalDataSourceAccess","metadataNameField":"externalDataSource","fields":["enabled:boolean","externalDataSource:string"]},{"name":"fieldLevelSecurities","metadataType":"fieldLevelSecurity","metadataNameField":"field","fields":["editable:boolean","field:string","hidden:boolean","readable:boolean"]},{"name":"fieldPermissions","metadataType":"fieldPermission","metadataNameField":"field","fields":["editable:boolean","field:string","hidden:boolean","readable:boolean"]},{"name":"layoutAssignments","metadataType":"layoutAssignment","metadataNameField":"layout","fields":["layout:string","recordType:string"]},{"name":"objectPermissions","metadataType":"objectPermission","metadataNameField":"object","fields":["allowCreate:boolean","allowDelete:boolean","allowEdit:boolean","allowRead:boolean","modifyAllRecords:boolean","object:string","viewAllRecords:boolean"]},{"name":"pageAccesses","metadataType":"pageAccess","metadataNameField":"apexPage","fields":["apexPage:string","enabled:boolean"]},{"name":"profileActionOverrides","metadataType":"profileActionOverride","metadataNameField":"actionName","fields":["actionName:string","content:string","formFactor:string","pageOrSobjectType:string","recordType:string","type:string"]},{"name":"recordTypeVisibilities","metadataType":"recordTypeVisibility","metadataNameField":"recordType","fields":["default:boolean","personAccountDefault:boolean","recordType:string","visible:boolean"]},{"name":"tabVisibilities","metadataType":"TabVisibility","metadataNameField":"tab","fields":["tab:string","visibility:string"]},{"name":"userPermissions","metadataType":"userPermission","metadataNameField":"name","fields":["enabled:boolean","name:string"]}]},{"categoryType":"Certificate","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"Certificate","metadataType":"Certificate","metadataNameField":"masterLabel","fields":["caSigned:boolean","encryptedWithPlatformEncryption:boolean","expirationDate:dateTime","keySize:int","privateKeyExportable:boolean"]}]},{"categoryType":"CustomObject","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"value","metadataType":"valueSetDefinition","metadataNameField":"fullName","fields":["fullName:string","color:string","default:boolean","description:string","isActive:boolean","label:string"]},{"name":"fields","metadataType":"customField","metadataNameField":"fullName","fields":["fullName:string","caseSensitive:boolean","customDataType:string","defaultValue:string","deleteConstraint:string","deprecated:boolean","description:string","displayFormat:string","displayLocationInDecimal:boolean","encrypted:boolean","externalDeveloperName:string","externalId:boolean","fieldManageability:string","formula:string","formulaTreatBlankAs:string","fullName:string","globalPicklist:string","indexed:boolean","inlineHelpText:string","isFilteringDisabled:boolean","isNameField:boolean","isSortingDisabled:boolean","reparentableMasterDetail:boolean","label:string","length:int","maskChar:string","maskType:string","metadataRelationship​ControllingField:string","populateExistingRows:boolean","precision:int","referenceTargetField:string","referenceTo:string","relationshipLabel:string","relationshipName:string","relationshipOrder:int","required:boolean","scale:int","startingNumber:int","stripMarkup:boolean","summarizedField:string","summaryForeignKey:string","summaryOperation:string","trackFeedHistory:boolean","trackHistory:boolean","trackTrending:boolean","trueValueIndexed:boolean","type:string","unique:boolean","visibleLines:int","writeRequiresMasterRead:boolean"]}]},{"categoryType":"CspTrustedSite","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"CspTrustedSite","metadataType":"cspTrustedSite","metadataNameField":"","fields":["description:string","endpointUrl:string","isActive:boolean"]}]},{"categoryType":"NamedCredential","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"NamedCredential","metadataType":"NamedCredential","metadataNameField":"","fields":["fullName:string","allowMergeFieldsInBody:boolean","allowMergeFieldsInHeader:boolean","authProvider:string","certificate:string","endpoint:string","generateAuthorizationHeader:boolean","label:string","oauthRefreshToken:string","oauthScope:string","oauthToken:string","password:string","principalType:string","protocol:string","username:string"]}]},{"categoryType":"Network","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"branding","metadataType":"Branding","metadataNameField":"","fields":["loginFooterText:string","loginLogo:string","pageFooter:string","pageHeader:string","primaryColor:string","primaryComplementColor:string","quaternaryColor:string","quaternaryComplementColor:string","secondaryColor:string","tertiaryColor:string","tertiaryComplementColor:string","zeronaryColor:string","zeronaryComplementColor:string"]},{"name":"networkMemberGroups","metadataType":"NetworkMemberGroup","metadataNameField":"","fields":["permissionSet:string","profile:string"]}]},{"categoryType":"PermissionSet","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"applicationVisibilities","metadataType":"applicationVisibility","metadataNameField":"application","fields":["application:string","visible:boolean"]},{"name":"classAccesses","metadataType":"classAccess","metadataNameField":"apexClass","fields":["apexClass:string","enabled:boolean"]},{"name":"customPermissions","metadataType":"customPermission","metadataNameField":"name","fields":["name:string","enabled:boolean"]},{"name":"externalDataSourceAccesses","metadataType":"externalDataSourceAccess","metadataNameField":"externalDataSource","fields":["externalDataSource:string","enabled:boolean"]},{"name":"fieldPermissions","metadataType":"fieldPermission","metadataNameField":"field","fields":["editable:boolean","field:string","readable:boolean"]},{"name":"objectPermissions","metadataType":"objectPermission","metadataNameField":"object","fields":["allowCreate:boolean","allowDelete:boolean","allowEdit:boolean","allowRead:boolean","modifyAllRecords:boolean","object:string","viewAllRecords:boolean"]},{"name":"tabSettings","metadataType":"tabSetting","metadataNameField":"tab","fields":["tab:string","visibility:string"]},{"name":"pageAccesses","metadataType":"pageAccess","metadataNameField":"apexPage","fields":["apexPage:string","enabled:boolean"]},{"name":"recordTypeVisibilities","metadataType":"recordTypeVisibility","metadataNameField":"recordType","fields":["recordType:string","visible:boolean"]},{"name":"userPermissions","metadataType":"userPermission","metadataNameField":"name","fields":["name:string","enabled:boolean"]}]},{"categoryType":"SamlSsoConfig","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"SamlSsoConfig","metadataType":"SamlSsoConfig","metadataNameField":"name","fields":["fullName:string","attributeName:string","attributeNameIdFormat:string","decryptionCertificate:string","errorUrl:string","executionUserId:string","identityLocation:string","identityMapping:string","issuer:string","loginUrl:string","logoutUrl:string","name:string","oauthTokenEndpoint:string","redirectBinding:boolean","requestSignatureMethod:string","salesforceLoginUrl:string","samlEntityId:string","samlJitHandlerId:string","samlVersion:string","userProvisioning:boolean","validationCert:string"]}]},{"categoryType":"Settings","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"dispositions","metadataType":"FileUploadAndDownloadSettings","metadataNameField":"fileType","fields":["behavior:string","filetype:string","securityRiskFileType:boolean"]},{"name":"ipRanges","metadataType":"IpRange","metadataNameField":"","fields":["description:string","start:string","end:string"]},{"name":"passwordPolicies","metadataType":"passswordPolicy","metadataNameField":"","fields":["apiOnlyUserHomePageURL:string","complexity:string","expiration:string","minimumPasswordLifetime:boolean","historyRestriction:string","lockoutInterval:string","maxLoginAttempts:string","minimumPasswordLength:string","obscureSecretAnswer:boolean","passwordAssistanceMessage:string","passwordAssistanceURL:string","questionRestriction:string"]},{"name":"sessionSettings","metadataType":"sessionSettings","metadataNameField":"","fields":["disableTimeoutWarning:boolean","enableCSPOnEmail:boolean","enableCSRFOnGet:boolean","enableCSRFOnPost:boolean","enableCacheAndAutocomplete:boolean","enableClickjackNonsetupSFDC:boolean","enableClickjackNonsetupUser:boolean","enableClickjackNonsetupUserHeaderless:boolean","enableClickjackSetup:boolean","enablePostForSessions:boolean","enableSMSIdentity:boolean","enforceIpRangesEveryRequest:boolean","forceLogoutOnSessionTimeout:boolean","forceRelogin:boolean","hstsOnForcecomSites:boolean","lockSessionsToDomain:boolean","lockSessionsToIp:boolean","logoutURL:boolean","requireHttpOnly:boolean","requireHttps:boolean","sessionTimeout:string"]},{"name":"preferences","metadataType":"OrganizationSettingsDetail","metadataNameField":"","fields":["settingName:string","setttingValue:boolean"]}]}]';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(rule);
        AddCCHRuleCriteriaExt handler = new AddCCHRuleCriteriaExt(sc);

        PageReference pageRef = Page.AddCCHRuleCriteria;
        Test.setCurrentPage(pageRef);

        handler.toggleLogic();
        System.assertEquals(3, handler.criteriaList.size());

        handler.removeCriteria();
        System.assertEquals(2, handler.criteriaList.size());

        handler.addNewCriteria();
        System.assertEquals(3, handler.criteriaList.size());

        handler.getNodePicklist();

        rule.Metadata_Type__c = 'Profile';

        handler.getNodePicklist();
        handler.getNodePicklist();

        handler.criteriaList[0].nodeName = 'name';
        handler.criteriaList[0].fieldName = 'value';
        pageRef.getParameters().put('cro', '1');
        handler.getFieldOperators();
        System.assertEquals('STRING', handler.criteriaList[0].fieldType);
        System.assertNotEquals(NULL, handler.criteriaList[0].operatorSet);

        handler.criteriaList[0].operator = 'e';

        handler.criteriaList[1].nodeName = 'applicationVisibility';
        handler.criteriaList[1].fieldName = 'default';
        pageRef.getParameters().put('cro', '2');
        handler.getFieldOperators();
        System.assertEquals('BOOLEAN', handler.criteriaList[1].fieldType);
        System.assertNotEquals(NULL, handler.criteriaList[1].operatorSet);

        handler.criteriaList[1].operator = '--None--';
        handler.saveCriterias();
        //System.assertEquals(1, [SELECT count() FROM Compliance_Rule_Criteria__c WHERE Compliance_Rule__c = :rule.Id]);
        System.assertEquals(FALSE, rule.filter_criteria__c.contains('AND'));
        pageRef.getParameters().put('cro', '2');
        handler.showFilterLogic = TRUE;
        handler.filterLogic = '1 AND 2 OR 3';

        handler.saveCriterias();
        System.assertEquals(FALSE, rule.filter_criteria__c.contains('OR'));
        handler.criteriaList[0].nodeName = 'name';
        handler.criteriaList[0].fieldName = 'value';
        pageRef.getParameters().put('cro', '1');
        handler.getFieldOperators();
        handler.criteriaList[0].operator = 'e';
        handler.criteriaList[1].nodeName = 'applicationVisibility';
        handler.criteriaList[1].fieldName = 'default';
        pageRef.getParameters().put('cro', '2');
        handler.getFieldOperators();
        handler.criteriaList[1].operator = 'n';
        handler.criteriaList[2].nodeName = 'applicationVisibility';
        handler.criteriaList[2].fieldName = 'default';
        pageRef.getParameters().put('cro', '3');
        handler.getFieldOperators();
        System.assertEquals('BOOLEAN', handler.criteriaList[1].fieldType);
        System.assertNotEquals(NULL, handler.criteriaList[1].operatorSet);

        handler.criteriaList[2].operator = 'e';

        handler.filterLogic = '1 AND 2 OR 3';

        handler.saveCriterias();
        System.assertEquals(FALSE, rule.filter_criteria__c.contains('OR'));
        handler.filterLogic = '(1 AND 2) OR 3';

        handler.saveCriterias();
        System.assertEquals(TRUE, rule.filter_criteria__c.contains('OR'));
        System.assertEquals(3, handler.criteriaList.size());

        AddCCHRuleCriteriaExt handler2 = new AddCCHRuleCriteriaExt(sc);
        PageReference pageRef2 = Page.AddCCHRuleCriteria;
        Test.setCurrentPage(pageRef2);
        System.assertEquals(TRUE, handler2.showFilterLogic);
        System.assertEquals('(1 AND 2) OR 3', handler2.filterLogic);
        System.assertNotEquals(0, handler2.legacyCriterias.size());

        AddCCHRuleCriteriaExt.testValidationBody = '{"ok":"compliance rule successfully validated!!"}';
        Boolean success = AddCCHRuleCriteriaExt.validateRuleCallout(rule);
        System.assertEquals(TRUE, success);
        System.assertEquals(TRUE, [SELECT Is_Valid__c FROM Compliance_Rule__c WHERE Id = :rule.Id].Is_Valid__c);

        AddCCHRuleCriteriaExt.testValidationBody = '{"error":"Test Error Message"}';
        handler.validateRuleFromPage();
        handler2.removeCriteria();
        System.assertEquals(FALSE, handler2.isValid);
        System.assertEquals(FALSE, [SELECT Is_Valid__c FROM Compliance_Rule__c WHERE Id = :rule.Id].Is_Valid__c);
        handler2.removeCriteria();
        System.assertEquals(2, handler2.criteriaList.size());
        System.assertEquals(1, handler2.criteriaMemento.size());

        handler2.saveCriterias();
        System.assertEquals(TRUE, rule.filter_criteria__c.contains('OR'));

        handler2.removeCriteria();
        System.assertEquals(1, handler2.criteriaList.size());
        System.assertEquals(2, handler2.criteriaMemento.size());

        handler2.filterLogic = '1 AND 2';
        handler2.saveCriterias();
        Test.stopTest();
    }
}