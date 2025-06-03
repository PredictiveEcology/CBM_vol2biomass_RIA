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
    # this are variables in inputed data.tables:SpatialUnitID, EcoBoundaryID, juris_id, ecozone, jur, eco, name, GrowthCurveComponentID, plotsRawCumulativeBiomass, checkInc
    expectsInput(objectName = "curveID", objectClass = "character",
                 desc = "Vector of column names that together, uniquely define growth curve id"),
    expectsInput(
      objectName = "table3",
      objectClass = "dataframe",
      desc = "Stem wood biomass model parameters for merchantable-sized trees from Boudewyn et al 2007",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table3.csv"
    ),
    expectsInput(
      objectName = "table4", objectClass = "dataframe", desc = "Stem wood biomass model parameters for nonmerchantable-sized trees from Boudewyn et al 2007",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table4.csv"
    ),
    expectsInput(
      objectName = "table5", objectClass = "dataframe", desc = "Stem wood biomass model parameters for sapling-sized trees from Boudewyn et al 2007",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table5.csv"
    ),
    expectsInput(
      objectName = "table6", objectClass = "dataframe", desc = "Proportion model parameters from Boudewyn et al 2007",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table6.csv"
    ),
    expectsInput(
      objectName = "table7", objectClass = "dataframe", desc = "Caps on proportion models from Boudewyn et al 2007",
      sourceURL = "https://nfi.nfis.org/resources/biomass_models/appendix2_table7.csv"
    ),
    expectsInput(
      objectName = "cbmAdmin", objectClass = "dataframe",
      desc = "Provides equivalent between provincial boundaries, CBM-id for provincial boundaries and CBM-spatial unit ids",
      sourceURL = "https://drive.google.com/file/d/1KiLW35XB-GgSdjIasFHDjXH6ilQXs7iy"
    ),
    expectsInput(objectName = "gcMeta",
                 objectClass = "dataframe",
                 desc = "Provides equivalent between provincial boundaries,
                 CBM-id for provincial boundaries and CBM-spatial unit ids",
                 sourceURL = NA),
    expectsInput(objectName = "gcMetaFile",
                 objectClass = "character",
                 desc = "File name and location for the user provided gcMeta dataframe",
                 sourceURL = "https://drive.google.com/file/d/1YmQ6sNucpEmF8gYkRMocPoeKt2P26ZiX"
                 ),
    expectsInput(objectName = "canfi_species",
                 objectClass = "dataframe",
                 desc = "File containing the possible species in the Boudewyn table - note
                 that if Boudewyn et al added species, this should be updated. Also note that such an update is very unlikely",
                 sourceURL = "https://drive.google.com/file/d/1l9b9V7czTZdiCIFX3dsvAsKpQxmN-Epo"),
    expectsInput(
      objectName = "userGcM3File", objectClass = "character",
      desc = paste("Pointer to the user file name for the files containing: GrowthCurveComponentID,Age,MerchVolume.",
                   "Default name userGcM3"),
      sourceURL = NA
    ),
    expectsInput(
      objectName = "userGcM3", objectClass = "dataframe",
      desc = "User file containing: GrowthCurveComponentID,Age,MerchVolume. Default name userGcM3",
      sourceURL = "https://drive.google.com/file/d/1BYHhuuhSGIILV1gmoo9sNjAfMaxs7qAj"
    ),
    expectsInput(objectName = "ecozones", objectClass = "data.table", desc = "the table linking the spu id, with the
                  disturbance_matrix_id and the events. The events are the possible raster values from the disturbance rasters of Wulder and White"),
    expectsInput(objectName = "gcids", objectClass = "data.table", desc = "the table linking the spu id, with the
                  disturbance_matrix_id and the events. The events are the possible raster values from the disturbance rasters of Wulder and White"),
    expectsInput(objectName = "spatialUnits", objectClass = "data.table", desc = "the table linking the spu id, with the
                  disturbance_matrix_id and the events. The events are the possible raster values from the disturbance rasters of Wulder and White")
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
    createsOutput(objectName = "growth_increments", objectClass = "matrix", desc = "Matrix of the 1/2 increment that will be used to create the gcHash"),
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
  ## user provides userGcM3: incoming cumulative m3/ha.
  ## table needs 3 columns: gcids, Age, MerchVolume
  # Here we check that ages increment by 1 each timestep,
  # if it does not, it will attempt to resample the table to make it so.
  ageJumps <- sim$userGcM3[, list(jumps = unique(diff(as.numeric(Age)))), by = "gcids"]
  idsWithJumpGT1 <- ageJumps[jumps > 1]$gcids
  if (length(idsWithJumpGT1)) {
    missingAboveMin <- sim$userGcM3[, approx(Age, MerchVolume, xout = setdiff(seq(0, max(Age)), Age)),
                          by = "gcids"]
    setnames(missingAboveMin, c("x", "y"), c("Age", "MerchVolume"))
    colsToKeep <- c("gcids", "Age", "MerchVolume")
    sim$userGcM3 <- sim$userGcM3[, ..colsToKeep]
    sim$userGcM3 <- rbindlist(list(sim$userGcM3, na.omit(missingAboveMin)))
    setorderv(sim$userGcM3, c("gcids", "Age"))

    # Assertion
    ageJumps <- sim$userGcM3[, list(jumps = unique(diff(as.numeric(Age)))), by = "gcids"]
    idsWithJumpGT1 <- ageJumps[jumps > 1]$gcids
    if (length(idsWithJumpGT1) > 0)
      stop("There are still yield curves that are not annually resolved")
  }


  # Creates/sets the vol2biomass outputs subfolder (inside the general outputs folder)
  figPath <- file.path(outputPath(sim), "CBM_vol2biomass_figures")
  sim$volCurves <- ggplot(data = sim$userGcM3, aes(x = Age, y = MerchVolume, group = gcids, colour = factor(gcids))) +
    geom_line() + theme_bw()
  SpaDES.core::Plots(sim$volCurves,
                     filename = "volCurves",
                     path = figPath,
                     ggsaveArgs = list(width = 7, height = 5, units = "in", dpi = 300),
                     types = "png")
  message("User: please look at the curve you provided via sim$volCurves or the volCurves.png file in the outputs folder")

  # START reducing Biomass model parameter tables --------------------------------------------
  userGcM3 <- sim$userGcM3
  if (is.null(sim$spatialDT)) stop("sim$spatialDT not found")
  spu <- unique(sim$spatialDT$spatial_unit_id)
  eco <- unique(sim$spatialDT$ecozones)

  thisAdmin <- sim$cbmAdmin[sim$cbmAdmin$SpatialUnitID %in% spu & sim$cbmAdmin$EcoBoundaryID %in% eco, ]
  
  # subsetting Boudewyn tables to the ecozones/admin boundaries of the study area.
  # Some ecozones/boundaries are not in these tables, in these cases, the function replaces them in
  # thisAdmin to the closest equivalent present in the Boudewyn tables.
  stable3 <- boudewynSubsetTables(sim$table3, thisAdmin, eco)
  stable4 <- boudewynSubsetTables(sim$table4, thisAdmin, eco)
  stable5 <- boudewynSubsetTables(sim$table5, thisAdmin, eco)
  stable6 <- boudewynSubsetTables(sim$table6, thisAdmin, eco)
  stable7 <- boudewynSubsetTables(sim$table7, thisAdmin, eco)
  
  # END reducing Biomass model parameter tables -----------------------------------------------

  # START Reading in user provided meta data for growth curves --------------------------------------------
  # This could be a complete data frame with the same columns as gcMetaEg.csv OR is could be only curve
  # id and species.
  
  ## Check that all required columns are available, and if not, add them:
  ## "gcids" "species" "canfi_species" "genus" "sw_hw"
 
  ## Check that all required columns are available, and if not, add them:
  ## "gcids" "species" "canfi_species" "genus" "sw_hw"
  if (!all(c(sim$curveID, "species") %in% names(sim$gcMeta))) stop(
    "gcMeta is missing column(s): ",
    paste(shQuote(setdiff(c(sim$curveID, "species"), names(sim$gcMeta))), collapse = ", "))
  
  if (any(!c("canfi_species", "genus", "sw_hw") %in% names(sim$gcMeta))){
    
    sppMatchTable <- CBMutils::sppMatch(
      sim$gcMeta$species, return = c("CanfiCode", "NFI", "Broadleaf"))[, .(
        canfi_species = CanfiCode,
        sw_hw         = data.table::fifelse(Broadleaf, "hw", "sw"),
        genus         = sapply(strsplit(NFI, "_"), `[[`, 1)
      )]
    
    sim$gcMeta <- cbind(
      sim$gcMeta[, .SD, .SDcols = setdiff(names(sim$gcMeta), names(sppMatchTable))],
      sppMatchTable)
    rm(sppMatchTable)
  }

  gcMeta <- sim$gcMeta
  setkey(gcMeta, gcids)
  # if (!unique(unique(userGcM3$gcids) == unique(gcMeta$gcids))) {
  #   stop("There is a missmatch in the growth curves of the userGcM3 and the gcMeta")
  # }
  
  # gcMeta also needs spatial_unit_id and ecozone.
  # Here we link the correct ecozones and subset to the gc used in this sim
  gcThisSim <- unique(sim$spatialDT[,.(gcids, spatial_unit_id, ecozones)])
  setkey(gcThisSim, gcids)
  setkey(gcMeta, gcids) 
  gcMeta <- merge(gcMeta, gcThisSim) 

  if (isFALSE(c("gcids", "species") %in% colnames(gcMeta))) {
    stop("Curve ID or species is missing from gcMeta")
  }
  
  # END Reading in user provided meta data for growth curves -----------------------------------------------

  ################
  warning("Modifying canfi_species 1211 ecozone to 1203") ##TODO: why do we do this?
  gcMeta[canfi_species == 1211, canfi_species := 1203]

  sim$gcMetaAllCols <- gcMeta
  
  # START processing curves from m3/ha to tonnes of C/ha then to annual increments
  # per above ground biomass pools -------------------------------------------
  
  # 1. Calculate the translation (result is cPools or "cumulative AGcarbon pools")
  
  # Matching is 1st on species, then on gcids which gives us location (admin,
  # spatial unit and ecozone)
  fullSpecies <- unique(gcMeta$species) 
  cPools <- cumPoolsCreate(fullSpecies, gcMeta, userGcM3,
                           stable3, stable4, stable5, stable6, stable7, thisAdmin
  ) |> Cache()
  
  # curveID are the columns use to make the unique levels in the factor gcids.
  # These factor levels are the link between the pixelGroups and the curve to be
  # use to growth their AGB.
  curveID <- c("gcids") ##TODO: remove hardcode when dataPrep is updated 
  if (!is.null(sim$level3DT)) {
    gcidsLevels <- levels(sim$level3DT$gcids)
    gcids <- factor(gcidsCreate(cPools[, ..curveID]))
  } else {
    gcids <- factor(gcidsCreate(cPools[, ..curveID]))
  }
  set(cPools, NULL, "id", gcids)
  set(cPools, NULL, "gcids", gcids)

  cbmAboveGroundPoolColNames <- "totMerch|fol|other"
  colNames <- grep(cbmAboveGroundPoolColNames, colnames(cPools), value = TRUE)

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

  # Fixing of non-smooth curves

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
  
  setkeyv(forestType, "gcids")
  cPoolsClean <- merge(cPoolsClean, forestType, by = "gcids",
                       all.x = TRUE, all.y = FALSE)
  
  gcids <- factor(gcidsCreate(gcMeta[, ..curveID]))
  set(gcMeta, NULL, "gcids", gcids)

  # 4. add sw/hw flag
  colsToUseForestType <- c("forest_type_id", "gcids") 
  forestType <- unique(gcMeta[, ..colsToUseForestType])
  
  #       # cbmTables$forest_type
  #       # id           name
  #       # 1  1       Softwood
  #       # 2  2      Mixedwood
  #       # 3  3       Hardwood
  #       # 4  9 Not Applicable
  
  # 5. finalize sim$growth_increments table
  outCols <- c("id", "ecozone", "totMerch", "fol", "other")
  cPoolsClean[, (outCols) := NULL]
  keepCols <- c("age", "gcids", "merch_inc", "foliage_inc", "other_inc", "forest_type_id")
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
    if (length(unique(increments[, min(age), by = "forest_type_id"]$V1)) != 1)
      stop("All ages should start at the same age for each curveID")
    if (length(unique(increments[, max(age), by = "forest_type_id"]$V1)) != 1)
      stop("All ages should end at the same age for each curveID")
  }
  ## replace increments that are NA with 0s

  increments[is.na(increments), ] <- 0
  sim$growth_increments <- increments
  
  # END process growth curves -------------------------------------------------------------------------------
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  
    if (!suppliedElsewhere("curveID", sim)) {
    sim$curveID <- c("gcids", "ecozones")
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

  # 1. growth and yield information
  ## TODO add a data manipulation to adjust if the m3 are not given on a yearly basis
  if (!suppliedElsewhere("userGcM3", sim)) {

    if (!suppliedElsewhere("userGcM3File", sim)) {
      sim$userGcM3File <- extractURL("userGcM3")
    }

      sim$userGcM3 <- prepInputs(url = sim$userGcM3File,
                                 fun = "data.table::fread",
                                 destinationPath = inputPath(sim),
                                 filename2 = "curve_points_table.csv")
    ## RIA 2020 specific
    sim$userGcM3[, V1 := NULL]
    names(sim$userGcM3) <- c("GrowthCurveComponentID", "Age", "MerchVolume")
  }

  # 2. meta info about growth and yield curves
  if (!suppliedElsewhere("gcMeta", sim)) {

    if (!suppliedElsewhere("gcMetaFile", sim)) {
      sim$gcMetaFile <- extractURL("gcMetaFile")
      }
    sim$gcMeta <- prepInputs(url = sim$gcMetaFile,
                                 fun = "data.table::fread",
                                 destinationPath = inputPath(sim),
                                 filename2 = "au_table.csv")

  }

  # 4. cbmAdmin: this is needed to match species and parameters. Boudewyn et al 2007
  # abbreviation and cbm spatial units and ecoBoundnary id is provided with the
  # adminName to avoid confusion.
  if (!suppliedElsewhere("cbmAdmin", sim)) {
    sim$cbmAdmin <-  prepInputs(url = extractURL("cbmAdmin"),
                                fun = "data.table::fread",
                                destinationPath = inputPath(sim),
                                filename2 = "cbmAdmin.csv")
  }

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}
