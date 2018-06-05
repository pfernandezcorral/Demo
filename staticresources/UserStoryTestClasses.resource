var metadataGrid2 = null;

var usTestClasses = usTestClasses || {};

usTestClasses.init = function(conf, force, isScalable, type, callback){
    conf.force = force;
    conf.isScalable = isScalable;
    metadataGrid2 = metadataGrid2 || new MetadataGrid2(conf);

    metadataGrid2.render(function() {
        console.info("usTestClasses::MetadataGrid:init grid rendered", conf);
        lockScreen();
        metadataGrid2.loadData(function() {
            console.info("usTestClasses::MetadataGrid:init grid data loaded");
            metadataGrid2.render();
            unlockScreen();
        });
    });

    if(callback){
        callback();
    }
};
usTestClasses.refreshCache = function() {
    metadataGrid2.refreshCache();
};

usTestClasses.save = function(){
    coGridHelper.datasource = metadataGrid2.datasource;
    coGridHelper.saveSelected(_config.data.id, _config.attachmentName, null, true, function(){
        location.href = '/apex/'+metadataGrid2.conf.ns+'userstoryselectedmetadata?id='+metadataGrid2.conf.data.id+'&inline=1'
    });
    window.parent.postMessage({"from":"userStorySelectedMetadata", "hasChanges":true,"change":null}, "*");
    return false;
 };

usTestClasses.cancel = function(){
    location.href = '/apex/'+metadataGrid2.conf.ns+'userstoryselectedmetadata?id='+metadataGrid2.conf.data.id+'&inline=1'
    return false;
};

usTestClasses.autoIdentify = function(usId){
    lockScreen();
    dw.u.getRemote(metadataGrid2.conf.server.autoSelectURL,
        function(res){
             if(res){
                 console.log('res identified');
                 if(res.copadoJobId){
                     console.debug('job id located');
                     jsCreateRunningJob(res.copadoJobId,'UserStoryTestClassesRetriever',usId,'Preparing...');
                 }
                 console.info('usTestClasses.autoIdentify:::success',res);
                 metadataGrid2.reloadSelections(0);
                 return false;
             } else if(res && res.error){
                console.error('usTestClasses.autoIdentify:::callback:::error',res.error);
                showMessage('ERROR',res.error);
                unlockScreen();
                return false;
             }
        },
        false,
        false,
        function(res){
            console.error('usTestClasses.autoIdentify:::errorFunction:::error',res.error);
            showMessage('ERROR',(res.error||res));
            unlockScreen();
            return false;
        },
        'autoTestSelection'
    );
}