defineModule(sim, list(
  name = "CBM_vol2biomass_RIA",
  description = paste("A module to prepare the user-provided growth and yield information for use",
                      "in the family of models spadesCBM - CBM-CFS3-like simulation of forest",
                      "carbon in the platform SpaDES. This module takes in user-provided m3/ha",
                      "and meta data for teh growth curves and returns annual increments for",
                      "the aboveground live c-pools."),
  keywords = "",
  authors = c(
    person("Céline",  "Boisvenue", email = "celine.boisvenue@nrcan-rncan.gc.ca", role = c("aut", "cre")),
    person("Camille", "Giuliano",  email = "camsgiu@gmail.com",                  role = c("ctb")),
    person("Susan",   "Murray",    email = "murray.e.susan@gmail.com",           role = c("ctb"))
  ),
  childModules = character(0),
  version = list(CBM_vol2biomass_RIA = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = deparse(list("README.txt", "CBM_vol2biomass_RIA.Rmd")),
  reqdPkgs = list(
    "PredictiveEcology/CBMutils@development (>=2.0.3.0005)",
    "ggforce", "ggplot2", "ggpubr", "googledrive", "mgcv", "quickPlot", "robustbase", "data.table", "patchwork"
  ),
  parameters = rbind(
    defineParameter(
      ".plotInitialTime", "numeric", NA, NA, NA,
      "Describes the simulation time at which the first plot event should occur."
    ),
    defineParameter(
      ".plotInterval", "numeric", NA, NA, NA,
      "Describes the simulation time interval between plot events."
    ),
    defineParameter(
      ".saveInitialTime", "numeric", NA, NA, NA,
      "Describes the simulation time at which the first save event should occur."
    ),
    defineParameter(
      ".saveInterval", "numeric", NA, NA, NA,
      "This describes the simulation time interval between save events."
    ),
    defineParameter(
      ".useCache", "logical", FALSE, NA, NA,
      paste(
        "Should this entire module be run with caching activated?",
        "This is generally intended for data-type modules, where stochasticity",
        "and time are not relevant"
      )
    )
  ),
  inputObjects = bindrows(
      expectsInput(
        objectName = "curveID", objectClass = "character",
        desc = "Column(s) uniquely defining each growth curve in `userGcSPU`, `userGcMeta`, and `userGcM3`."),
      expectsInput(
        objectName = "userGcSPU", objectClass = "data.frame",
        desc = "Growth curve locations with columns `curveID` and 'spatial_unit_id'"),
      expectsInput(
        objectName = "userGcMeta", objectClass = "data.table",
        desc = "Growth curve metadata.", #TODO: Define default data source
        sourceURL = "https://drive.google.com/file/d/1YmQ6sNucpEmF8gYkRMocPoeKt2P26ZiX"),
      expectsInput(
        objectName = "userGcMetaURL", objectClass = "character",
        desc = "URL for userGcMeta"),
      expectsInput(
        objectName = "userGcM3", objectClass = "dataframe",
        desc = "User file containing: GrowthCurveComponentID,Age,MerchVolume. Default name userGcM3",
        sourceURL = "https://drive.google.com/file/d/1BYHhuuhSGIILV1gmoo9sNjAfMaxs7qAj"),
      expectsInput(
        objectName = "userGcM3URL", objectClass = "character",
        desc = "URL for userGcM3"),
      expectsInput(
        objectName = "cbmAdmin", objectClass = "dataframe",
        desc = "Provides equivalent between provincial boundaries, CBM-id for provincial boundaries and CBM-spatial unit ids",
        sourceURL = "https://drive.google.com/file/d/1KiLW35XB-GgSdjIasFHDjXH6ilQXs7iy"),
      expectsInput(
        objectName = "cbmAdminURL", objectClass = "character",
        desc = "URL for cbmAdmin"),
    expectsInput(
      objectName = "table3", objectClass = "data.frame",
      desc = "Stem wood biomass model parameters for merchantable-sized trees from Boudewyn et al 2007",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table3.csv"),
    expectsInput(
      objectName = "table3URL", objectClass = "character",
      desc = "URL for table 3"),
    expectsInput(
      objectName = "table4", objectClass = "data.frame", desc = "Stem wood biomass model parameters for nonmerchantable-sized trees from Boudewyn et al 2007",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table4.csv"),
    expectsInput(
      objectName = "table4URL", objectClass = "character",
      desc = "URL for table 4"),
    expectsInput(
      objectName = "table5", objectClass = "data.frame",
      desc = "Stem wood biomass model parameters for sapling-sized trees from Boudewyn et al. 2007.",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table5.csv"),
    expectsInput(
      objectName = "table5URL", objectClass = "character",
      desc = "URL for table 5"),
    expectsInput(
      objectName = "table6", objectClass = "data.frame",
      desc = "Proportion model parameters from Boudewyn et al. 2007",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table6.csv"),
    expectsInput(
      objectName = "table6URL", objectClass = "character",
      desc = "URL for table 6"),
    expectsInput(
      objectName = "table7", objectClass = "data.frame",
      desc = "Caps on proportion models from Boudewyn et al. 2007.",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table7.csv"),
    expectsInput(
      objectName = "table7URL", objectClass = "character",
      desc = "URL for table 7")
  ),
  outputObjects = bindrows(
    createsOutput(objectName = NA, objectClass = NA, desc = NA),
    createsOutput(objectName = "volCurves", objectClass = "plot",
                  desc = "Plot of all the growth curve provided by the user"),
    createsOutput(objectName = "plotsRawCumulativeBiomass", objectClass = "plot",
                  desc = "Plot of cumulative m3/ha curves translated into tonnes of carbon/ha, per AG pool, prior to any smoothing"),
    createsOutput(objectName = "gcMetaAllCols",
                  objectClass = "dataframe",
                  desc = "gcMeta as above plus ecozones"),
    createsOutput(objectName = "cPoolsClean",
                  objectClass = "dataframe",
                  desc = "Cumulative carbon increments after smoothing."),
    createsOutput(objectName = "growth_increments", objectClass = "matrix", 
                  desc = "Matrix of the 1/2 increment that will be used to create the gcHash"),
    createsOutput(objectName = "gcHash", objectClass = "environment", desc = "Environment pointing to each gcID, that is itself an environment,
                  pointing to each year of growth for all AG pools.Hashed matrix of the 1/2 growth increment.
                  This is used in the c++ functions to increment AG pools two times in an annual event (in the spadesCBMcore.R module.")
  )
))

doEvent.CBM_vol2biomass_RIA <- function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      
      sim <- Init(sim)
      
    },
    warning(noEventWarning(sim))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  # Check input
  if ("gcids" %in% sim$curveID)           stop("'curveID' cannot contain \"gcids\"")
  if ("gcids" %in% names(sim$userGcMeta)) stop("'userGcMeta' cannot contain \"gcids\"")
  if ("gcids" %in% names(sim$userGcM3))   stop("'userGcM3' cannot contain \"gcids\"")
  
  sim$userGcSPU  <- data.table::as.data.table(sim$userGcSPU)
  sim$userGcMeta <- data.table::as.data.table(sim$userGcMeta)
  sim$userGcM3   <- data.table::as.data.table(sim$userGcM3)

  ## user provides userGcM3: incoming cumulative m3/ha.
  ## table needs 3 columns: gcids, Age, MerchVolume
  # Here we check that ages increment by 1 each timestep,
  # if it does not, it will attempt to resample the table to make it so.
  ageJumps <- sim$userGcM3[, list(jumps = unique(diff(as.numeric(Age)))), by = "curveID"]
  idsWithJumpGT1 <- ageJumps[jumps > 1]$gcids
  if (length(idsWithJumpGT1) > 0) {
    missingAboveMin <- sim$userGcM3[, approx(Age, MerchVolume, xout = setdiff(seq(0, max(Age)), Age)),
                          by = "curveID"]
    setnames(missingAboveMin, c("x", "y"), c("Age", "MerchVolume"))
    colsToKeep <- c("curveID", "Age", "MerchVolume")
    sim$userGcM3 <- sim$userGcM3[, ..colsToKeep]
    sim$userGcM3 <- rbindlist(list(sim$userGcM3, na.omit(missingAboveMin)))
    setorderv(sim$userGcM3, c("curveID", "Age"))

    # Assertion
    ageJumps <- sim$userGcM3[, list(jumps = unique(diff(as.numeric(Age)))), by = "curveID"]
    idsWithJumpGT1 <- ageJumps[jumps > 1]$curveID
    if (length(idsWithJumpGT1) > 0)
      stop("There are still yield curves that are not annually resolved")
  }


  # Creates/sets the vol2biomass outputs subfolder (inside the general outputs folder)
  figPath <- file.path(outputPath(sim), "CBM_vol2biomass_figures")
  sim$volCurves <- ggplot(data = sim$userGcM3, aes(x = Age, y = MerchVolume, group = curveID, colour = factor(curveID))) +
    geom_line() + theme_bw()
  SpaDES.core::Plots(sim$volCurves,
                     filename = "volCurves",
                     path = figPath,
                     ggsaveArgs = list(width = 7, height = 5, units = "in", dpi = 300),
                     types = "png")
  message("User: please look at the curve you provided via sim$volCurves or the volCurves.png file in the outputs folder")

  # START reducing Biomass model parameter tables --------------------------------------------
  thisAdmin <- sim$cbmAdmin[sim$cbmAdmin$SpatialUnitID %in% na.omit(sim$userGcSPU$spatial_unit_id), ]
  
  # subsetting Boudewyn tables to the ecozones/admin boundaries of the study area.
  # Some ecozones/boundaries are not in these tables, in these cases, the function replaces them in
  # thisAdmin to the closest equivalent present in the Boudewyn tables.
  stable3 <- boudewynSubsetTables(sim$table3, thisAdmin, thisAdmin$EcoBoundaryID)
  stable4 <- boudewynSubsetTables(sim$table4, thisAdmin, thisAdmin$EcoBoundaryID)
  stable5 <- boudewynSubsetTables(sim$table5, thisAdmin, thisAdmin$EcoBoundaryID)
  stable6 <- boudewynSubsetTables(sim$table6, thisAdmin, thisAdmin$EcoBoundaryID)
  stable7 <- boudewynSubsetTables(sim$table7, thisAdmin, thisAdmin$EcoBoundaryID)
  
  # END reducing Biomass model parameter tables -----------------------------------------------

  # START Reading in user provided meta data for growth curves --------------------------------------------
  # This could be a complete data frame with the same columns as gcMetaEg.csv OR is could be only curve
  # id and species.
  if (!all(c(sim$curveID, "species") %in% names(sim$userGcMeta))) stop(
    "userGcMeta is missing column(s): ",
    paste(shQuote(setdiff(c(sim$curveID, "species"), names(sim$userGcMeta))), collapse = ", "))
  
  if (any(!c("canfi_species", "genus", "sw_hw") %in% names(sim$userGcMeta))){
    
    sppMatchTable <- CBMutils::sppMatch(
      sim$userGcMeta$species, return = c("CanfiCode", "NFI", "Broadleaf"))[, .(
        canfi_species = CanfiCode,
        sw_hw         = data.table::fifelse(Broadleaf, "hw", "sw"),
        genus         = sapply(strsplit(NFI, "_"), `[[`, 1)
      )]
    
    sim$userGcMeta <- cbind(
      sim$userGcMeta[, .SD, .SDcols = setdiff(names(sim$userGcMeta), names(sppMatchTable))],
      sppMatchTable)
    rm(sppMatchTable)
  }
  
  # END Reading in user provided meta data for growth curves -----------------------------------------------

  ################
  warning("Modifying canfi_species 1211 ecozone to 1203") ##TODO: why do we do this?
  sim$userGcMeta[canfi_species == 1211, canfi_species := 1203]

  sim$gcMetaAllCols <- sim$userGcMeta
  
  # START processing curves from m3/ha to tonnes of C/ha then to annual increments
  # per above ground biomass pools -------------------------------------------
  
  # Create a new unique key defining each growth curve and spatial_unit_id
  sim$userGcSPU <- cbind(
    gcids = factor(
      CBMutils::gcidsCreate(sim$userGcSPU[, .SD, .SDcols = c("spatial_unit_id", sim$curveID)])
    ),
    sim$userGcSPU)
  data.table::setkey(sim$userGcSPU, gcids)
  
  sim$gcMeta <- merge(sim$userGcSPU, sim$userGcMeta, by = sim$curveID)
  data.table::setcolorder(sim$gcMeta, which(names(sim$gcMeta) == "gcids"))
  data.table::setkey(sim$gcMeta, gcids)
  
  if (!"ecozones" %in% names(sim$gcMeta)){
    sim$gcMeta <- merge(
      sim$gcMeta,
      sim$cbmAdmin[, .(spatial_unit_id = SpatialUnitID, ecozones = EcoBoundaryID)],
      by = "spatial_unit_id")
  }
  gcM3 <- merge(sim$userGcSPU, sim$userGcM3, by = sim$curveID, allow.cartesian = TRUE)[
    , .(gcids, Age, MerchVolume)]
  data.table::setkey(gcM3, gcids, Age)
  
  # 1. Calculate the translation (result is cPools or "cumulative AGcarbon pools")
  
  # Matching is 1st on species, then on gcids which gives us location (admin,
  # spatial unit and ecozone)
  fullSpecies <- unique(sim$gcMeta$species)
  
  cPools <- cumPoolsCreate(fullSpecies, sim$gcMeta, gcM3,
                           stable3, stable4, stable5, stable6, stable7, thisAdmin
  ) |> Cache()
  
  # 2. Make sure the provided curves are annual
  ## if not, we need to extrapolate to make them annual
  minAgeId <- cPools[,.(minAge = max(0, min(age) - 1)), by = "gcids"]
  fill0s <- minAgeId[,.(age = seq(from = 0, to = minAge, by = 1)), by = "gcids"]
  # these are going to be 0s
  carbonVars <- data.table(gcids = unique(fill0s$gcids),
                           totMerch = 0,
                           fol = 0,
                           other = 0 )
  fiveOf7cols <- fill0s[carbonVars, on = "gcids"]
  otherVars <- cPools[,.(id = unique(id), ecozone = unique(ecozone)), by = "gcids"]
  add0s <- fiveOf7cols[otherVars, on = "gcids"]
  cPoolsRaw <- rbindlist(list(cPools,add0s), use.names = TRUE)
  set(cPoolsRaw, NULL, "age", as.numeric(cPoolsRaw$age))
  setorderv(cPoolsRaw, c("gcids", "age"))
  
  # 3. Fixing of non-smooth curves
  message(crayon::red("User: please inspect figures of the raw and smoothed translation of your growth curves in: ",
                      figPath))
  
  if (any(cPoolsRaw$gcids == "39_4102001")) {
    cPoolsRaw[gcids == "39_4102001", fol   := cPoolsRaw[gcids == "39_4101001", fol]]
    cPoolsRaw[gcids == "39_4102001", other := cPoolsRaw[gcids == "39_4101001", other]]
  }
  if (any(cPoolsRaw$gcids == "39_4103001")) {
    cPoolsRaw[gcids == "39_4103001", fol   := cPoolsRaw[gcids == "39_4101001", fol]]
    cPoolsRaw[gcids == "39_4103001", other := cPoolsRaw[gcids == "39_4101001", other]]
  }
  

  # Smooth curves
  cPoolsClean <- cumPoolsSmooth(cPoolsRaw
                                  ) |> Cache()

  #Note: this will produce a warning if one of the curve smoothing efforts doesn't converge
  cPoolsSmoothPlot <- m3ToBiomPlots(inc = cPoolsClean,
                                    title = "Cumulative merch/fol/other by gcid")
  for (i in seq_along(cPoolsSmoothPlot)){
    SpaDES.core::Plots(cPoolsSmoothPlot[[i]],
                       filename = paste0("cPools_smoothed_postChapmanRichards_", i, ".png"),
                       path = figPath,
                       ggsaveArgs = list(width = 10, height = 5, units = "in", dpi = 300),
                       types = "png")
  }
  
  ## keeping the new curves - at this point they are still cumulative
  colNames <- c("totMerch", "fol", "other")
  set(cPoolsClean, NULL, colNames, NULL)
  colNamesNew <- grep("totMerch|fol|other", colnames(cPoolsClean), value = TRUE)
  setnames(cPoolsClean, old = colNamesNew, new = colNames)
  
  # 4. Calculating Increments
  incCols <- c("incMerch", "incFol", "incOther")
  cPoolsClean[, (incCols) := lapply(.SD, function(x) c(NA, diff(x))), .SDcols = colNames,
              by = eval("gcids")]
  colsToUse33 <- c("age", "gcids", incCols)
  rawIncPlots <- m3ToBiomPlots(inc = cPoolsClean[, ..colsToUse33],
                               title = "Increments")
  for (i in seq_along(rawIncPlots)){
    SpaDES.core::Plots(rawIncPlots[[i]],
                       filename = paste0("increments_", i, ".png"),
                       path = figPath,
                       ggsaveArgs = list(width = 10, height = 5, units = "in", dpi = 300),
                       types = "png")
  }
  
  sim$cPoolsClean <- cPoolsClean

  # 4. add sw/hw flag
  sim$gcMeta <- sim$gcMeta[, forest_type_id := ifelse(sw_hw == "sw", 1, 3)]
  colsToUseForestType <- c("sw_hw", "gcids")
  forestType <- unique(sim$gcMeta[, ..colsToUseForestType])
  
  #       # cbmTables$forest_type
  #       # id           name
  #       # 1  1       Softwood
  #       # 2  2      Mixedwood
  #       # 3  3       Hardwood
  #       # 4  9 Not Applicable
  
  setkeyv(forestType, "gcids")
  cPoolsClean <- merge(cPoolsClean, forestType, by = "gcids",
                       all.x = TRUE, all.y = FALSE)
  
  # 5. finalize sim$growth_increments table
  outCols <- c("id", "ecozone", "totMerch", "fol", "other")
  cPoolsClean[, (outCols) := NULL]
  keepCols <- c("gcids", "age", "merch_inc", "foliage_inc", "other_inc", "forest_type_id")
  incCols <- c("merch_inc", "foliage_inc", "other_inc")
  setnames(cPoolsClean,names(cPoolsClean),
           keepCols)
  increments <- cPoolsClean[, (incCols) := list(
    merch_inc, foliage_inc, other_inc
  )]
  setorderv(increments, c("gcids", "age"))

  # Assertions
  if (isTRUE(P(sim)$doAssertions)) {
    # All should have same min age
    if (length(unique(increments[, min(age), by = "sw_hw"]$V1)) != 1)
      stop("All ages should start at the same age for each curveID")
    if (length(unique(increments[, max(age), by = "sw_hw"]$V1)) != 1)
      stop("All ages should end at the same age for each curveID")
  }
  
  
  ## replace increments that are NA with 0s
  increments[is.na(increments), ] <- 0
  sim$growth_increments <- increments
  
  # END process growth curves -------------------------------------------------------------------------------
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  
  # Growth and yield
  if (!suppliedElsewhere("curveID", sim)) {
    sim$curveID <- "curveID"
  }
  
  if (!suppliedElsewhere("userGcMeta", sim)) {
    if (!suppliedElsewhere("userGcMetaURL", sim)) {
      sim$userGcMetaURL <- extractURL("userGcMeta")
    }
    
    sim$userGcMeta <- prepInputs(url = sim$userGcMetaURL,
                                 targetFile = "gcMetaEg.csv",
                                 destinationPath = inputPath(sim),
                                 fun = fread,
                                 purge = 7
    )
    data.table::setnames(sim$userGcMeta, "gcids", "curveID")
    data.table::setkey(sim$userGcMeta, curveID)
    
    sim$userGcMeta$sw_hw <- sapply(sim$userGcMeta$forest_type_id == 1, ifelse, "sw", "hw")
  }
  
  if (!suppliedElsewhere("userGcM3", sim)){
    
    if (suppliedElsewhere("userGcM3URL", sim)){
      
      sim$userGcM3 <- prepInputs(url = sim$userGcM3URL,
                                 destinationPath = inputPath(sim),
                                 fun = "data.table::fread")
      
    }else{
      
      message("User has not supplied growth curves ('userGcM3' or 'userGcM3URL'). ",
              "Defaults for Saskatchewan will be used.")
      
      sim$userGcM3 <- prepInputs(url = extractURL("userGcM3"),
                                 destinationPath = inputPath(sim),
                                 targetFile = "userGcM3.csv",
                                 fun = "data.table::fread")
      data.table::setnames(sim$userGcM3, names(sim$userGcM3), c("curveID", "Age", "MerchVolume"))
      data.table::setkeyv(sim$userGcM3, c("curveID", "Age"))
      
    }
  }
  
  # cbmAdmin: this is needed to match species and parameters. Boudewyn et al 2007
  # abbreviation and cbm spatial units and ecoBoudnary id is provided with the
  # adminName to avoid confusion.
  if (!suppliedElsewhere("cbmAdmin", sim)) {
    if (!suppliedElsewhere("cbmAdminURL", sim)) {
      sim$cbmAdminURL <- extractURL("cbmAdmin")
    }
    sim$cbmAdmin <- prepInputs(url = sim$cbmAdminURL,
                               targetFile = "cbmAdmin.csv",
                               destinationPath = inputPath(sim),
                               fun = fread)
  }
  
  ## tables from Boudewyn -- all downloaded from the NFIS site.
  ## however, NFIS changes the tables and seems to forget parameter columns at times.
  if (!suppliedElsewhere("table3", sim)) {
    if (!suppliedElsewhere("table3URL", sim)) {
      sim$table3URL <- extractURL("table3")
    }
    sim$table3 <- prepInputs(url = sim$table3URL,
                             destinationPath = inputPath(sim),
                             fun = fread)
  }
  
  if (!suppliedElsewhere("table4", sim)) {
    if (!suppliedElsewhere("table4URL", sim)) {
      sim$table4URL <- extractURL("table4")
    }
    sim$table4 <- prepInputs(url = sim$table4URL,
                             destinationPath = inputPath(sim),
                             fun = fread)
  }
  
  
  if (!suppliedElsewhere("table5", sim)) {
    if (!suppliedElsewhere("table5URL", sim)) {
      sim$table5URL <- extractURL("table5")
    }
    sim$table5 <- prepInputs(url = sim$table5URL,
                             destinationPath = inputPath(sim),
                             fun = fread)
  }
  
  
  if (!suppliedElsewhere("table6", sim)) {
    if (!suppliedElsewhere("table6URL", sim)) {
      sim$table6URL <- extractURL("table6")
    }
    sim$table6 <- prepInputs(url = sim$table6URL,
                             destinationPath = inputPath(sim),
                             fun = fread)
  }
  
  if (!suppliedElsewhere("table7", sim)) {
    if (!suppliedElsewhere("table7URL", sim)) {
      sim$table7URL <- extractURL("table7")
    }
    sim$table7 <- prepInputs(url = sim$table7URL,
                             destinationPath = inputPath(sim),
                             fun = fread)
  }

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}
