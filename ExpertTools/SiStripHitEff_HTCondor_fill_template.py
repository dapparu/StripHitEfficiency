import FWCore.ParameterSet.Config as cms
import FWCore.ParameterSet.VarParsing as VarParsing
import FWCore.Utilities.FileUtils as FileUtils

process = cms.Process("HitEff")
process.load("Configuration.StandardSequences.GeometryRecoDB_cff")
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')

from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, 'auto:run2_data', '')  

process.source = cms.Source("EmptyIOVSource",
    firstValue = cms.uint64(FIRSTRUN),
    lastValue = cms.uint64(LASTRUN),
    timetype = cms.string('runnumber'),
    interval = cms.uint64(1)
)

# setup 'analysis'  options
options = VarParsing.VarParsing ('analysis')

options.register ('FileList',
                  'filelist.txt', # default value
                  VarParsing.VarParsing.multiplicity.singleton, 
                  VarParsing.VarParsing.varType.string,
                  "FileList in DAS format")

options.register ('JobNumber',
                  0, # default value
                  VarParsing.VarParsing.multiplicity.singleton,
                  VarParsing.VarParsing.varType.int,
                  "job number")

options.register ('NofFilesPerJob',
                  1, #default value
                  VarParsing.VarParsing.multiplicity.singleton,
                  VarParsing.VarParsing.varType.int,
                  "number of files per job")

# get and parse the command line arguments
options.parseArguments()

#name of the output file containing the tree

firstFileNum = options.JobNumber*options.NofFilesPerJob
filelist = FileUtils.loadListFromFile (options.FileList)
readFiles = cms.untracked.vstring( *filelist)
selected_readFiles = cms.untracked.vstring( readFiles[firstFileNum:firstFileNum+options.NofFilesPerJob] )
process.maxEvents = cms.untracked.PSet( input = cms.untracked.int32(1))

process.SiStripHitEff = cms.EDAnalyzer("SiStripHitEffFromCalibTree",
    CalibTreeFilenames = cms.untracked.vstring(
        selected_readFiles
    ),
    Threshold         = cms.double(0.1),
    nModsMin          = cms.int32(5),
    doSummary         = cms.int32(0),
    #ResXSig           = cms.untracked.double(5),
    SinceAppendMode   = cms.bool(True),
    IOVMode           = cms.string('Run'),
    Record            = cms.string('SiStripBadStrip'),
    doStoreOnDB       = cms.bool(True),
    BadModulesFile    = cms.untracked.string("BadModules_input.txt"),   # default "" no input
    AutoIneffModTagging = cms.untracked.bool(True),   # default true, automatic limit for each layer to identify inefficient modules
    ClusterMatchingMethod  = cms.untracked.int32(4),     # default 0  case0,1,2,3,4
    ClusterTrajDist   = cms.untracked.double(15),   # default 64
    StripsApvEdge     = cms.untracked.double(10),   # default 10  
    UseOnlyHighPurityTracks = cms.untracked.bool(True), # default True
    SpaceBetweenTrains = cms.untracked.int32(25),   # default 25
    ShowEndcapSides   = cms.untracked.bool(False),  # default True
    ShowRings         = cms.untracked.bool(False),  # default False
    showTOB6TEC9      = cms.untracked.bool(False),  # default False
    TkMapMin          = cms.untracked.double(0.90), # default 0.90
    EffPlotMin        = cms.untracked.double(0.90), # default 0.90
    Title             = cms.string(' Hit Efficiency ')
)

process.PoolDBOutputService = cms.Service("PoolDBOutputService",
    BlobStreamerName = cms.untracked.string('TBufferBlobStreamingService'),
    DBParameters = cms.PSet(
        authenticationPath = cms.untracked.string('/afs/cern.ch/cms/DB/conddb')
    ),
    timetype = cms.untracked.string('runnumber'),
    connect = cms.string('sqlite_file:dbfile.db'),
    toPut = cms.VPSet(cms.PSet(
        record = cms.string('SiStripBadStrip'),
        tag = cms.string('SiStripHitEffBadModules')
    ))
)

process.TFileService = cms.Service("TFileService",
        fileName = cms.string('SiStripHitEffHistos_fillFILLNUMBER.root')  
)

process.allPath = cms.Path(process.SiStripHitEff)

