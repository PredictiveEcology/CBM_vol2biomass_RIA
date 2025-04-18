defineModule(sim, list(
  name = "CBM_vol2biomass_RIA",
  description = paste("A module to prepare the user-provided growth and yield information for use",
                      "in the family of models spadesCBM - CBM-CFS3-like simulation of forest",
                      "carbon in the platform SpaDES. This module takes in user-provided m3/ha",
                      "and meta data for teh growth curves and returns annual increments for",
                      "the aboveground live c-pools."),
  keywords = "",
  authors = c(
    person("Celine", "Boisvenue", email = "celine.boisvenue@nrcan-rncan.gc.ca", role = c("aut", "cre"))
  ),
  childModules = character(0),
  version = list(CBM_vol2biomass_RIA = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = deparse(list("README.txt", "CBM_vol2biomass_RIA.Rmd")),
  reqdPkgs = list(
    "ggplot2", "ggpubr", "mgcv", "quickPlot", "PredictiveEcology/CBMutils@development",
    "robustbase", "ggforce"
  ),
  parameters = rbind(
    # defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
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
    # expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
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
    # createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = NA, objectClass = NA, desc = NA),
    createsOutput(objectName = "volCurves", objectClass = "plot",
                  desc = "Plot of all the growth curve provided by the user"),
    createsOutput(objectName = "plotsRawCumulativeBiomass", objectClass = "plot",
                  desc = "Plot of cumulative m3/ha curves translated into tonnes of carbon/ha, per AG pool, prior to any smoothing"),
    createsOutput(objectName = "gcMetaAllCols",
                  objectClass = "dataframe",
                  desc = "gcMeta as above plus ecozones"),
    createsOutput(objectName = "cumPoolsClean",
                  objectClass = "dataframe",
                  desc = "Cumulative carbon increments after smoothing."),
    createsOutput(objectName = "growth_increments", objectClass = "matrix", desc = "Matrix of the 1/2 increment that will be used to create the gcHash"),
    createsOutput(objectName = "gcHash", objectClass = "environment", desc = "Environment pointing to each gcID, that is itself an environment,
                  pointing to each year of growth for all AG pools.Hashed matrix of the 1/2 growth increment.
                  This is used in the c++ functions to increment AG pools two times in an annual event (in the spadesCBMcore.R module.")
  )
))

## event types
#   - type `init` is required for initialization

doEvent.CBM_vol2biomass_RIA <- function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      ### check for more detailed object dependencies:
      ### (use `checkObject` or similar)

      # do stuff for this event
      sim <- Init(sim)

      # schedule future event(s)
      sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "CBM_vol2biomass_RIA", "plot")
      sim <- scheduleEvent(sim, P(sim)$.saveInitialTime, "CBM_vol2biomass_RIA", "save")
    },
    plot = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event

      # plotFun(sim) # uncomment this, replace with object to plot
      # schedule future event(s)

      # e.g.,
      # sim <- scheduleEvent(sim, time(sim) + P(sim)$.plotInterval, "CBM_vol2biomass_RIA", "plot")

      # ! ----- STOP EDITING ----- ! #
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
      "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'",
      sep = ""
    ))
  )
  return(invisible(sim))
}

## event functions

Init <- function(sim) {
  # user provides userGcM3: incoming cumulative m3/ha
  # plot
  # Test for steps of 1 in the yield curves
  ageJumps <- sim$userGcM3[, list(jumps = unique(diff(as.numeric(Age)))), by = "gcids"]
  idsWithJumpGT1 <- ageJumps[jumps > 1]$gcids
  if (length(idsWithJumpGT1)) {
    missingAboveMin <- sim$userGcM3[, approx(Age, MerchVolume, xout = setdiff(seq(0, max(Age)), Age)),
                          by = "gcids"]
    setnames(missingAboveMin, c("x", "y"), c("Age", "MerchVolume"))
    missingAboveMin <- na.omit(missingAboveMin)
    colsToKeep <- c("gcids", "Age", "MerchVolume")
    sim$userGcM3 <- sim$userGcM3[, ..colsToKeep]
    sim$userGcM3 <- rbindlist(list(sim$userGcM3, missingAboveMin))
    setorderv(sim$userGcM3, c("gcids", "Age"))

    # Assertion
    ageJumps <- sim$userGcM3[, list(jumps = unique(diff(as.numeric(Age)))), by = "gcids"]
    idsWithJumpGT1 <- ageJumps[jumps > 1]$gcids
    if (length(idsWithJumpGT1) > 0)
      stop("There are still yield curves that are not annually resolved")
  }


  sim$volCurves <- ggplot(data = sim$userGcM3, aes(x = Age, y = MerchVolume, group = gcids, colour = gcids)) +
    geom_line() ## TODO: move to plotInit event
  message("User: please look at the curve you provided via sim$volCurves")

  ## not all curves provided are used in the simulation - and ***FOR NOW*** each
  ## pixels only gets assigned one growth curve (no transition, no change in
  ## productivity).

  # Reducing Biomass model parameter tables from Boudewyn to watch we need for
  # the sim -----------------------------------------------

  userGcM3 <- sim$userGcM3
  spu <- unique(sim$spatialUnits)
  eco <- unique(sim$ecozones)

  thisAdmin <- sim$cbmAdmin[sim$cbmAdmin$SpatialUnitID %in% spu & sim$cbmAdmin$EcoBoundaryID %in% eco, ]

  # START reducing Biomass model parameter tables -----------------------------------------------
  # not all ecozones are in tables 3-7. There may be some mismatch here.
  # these are the ecozones in the tables
  # id               name
  # 4       Taiga Plains
  # 5  Taiga Shield West
  # 6 Boreal Shield West
  # 7  Atlantic Maritime
  # 9      Boreal Plains
  # 10  Subhumid Prairies
  # 12  Boreal Cordillera
  # 13   Pacific Maritime
  # 14 Montane Cordillera
  # these are the ones that are not.
  # id               name
  # 8   Mixedwood Plains  - 7  Atlantic Maritime
  # 11   Taiga Cordillera - 4 taiga plains
  # 15      Hudson Plains - 6 Boreal Shield West
  # 16  Taiga Shield East - 5  Taiga Shield West
  # 17 Boreal Shield East - 6 Boreal Shield West
  # 18  Semiarid Prairies - 10  Subhumid Prairies

  ecoNotInT <- c(8, 11, 15, 16, 17, 18)
  if (any(eco %in% ecoNotInT)) {
    EcoBoundaryID <- c(7, 4, 6, 5, 6, 10)
    ecoReplace <- data.table(ecoNotInT, EcoBoundaryID)
    thisAdmin <- merge(ecoReplace, thisAdmin, by.x = "ecoNotInT", by.y = "EcoBoundaryID")
  }

  if (any(eco %in% ecoNotInT)) {
    stable3 <- as.data.table(sim$table3[sim$table3$juris_id %in% thisAdmin$abreviation &
                                          sim$table3$ecozone %in% thisAdmin$EcoBoundaryID, ])
    stable4 <- as.data.table(sim$table4[sim$table4$juris_id %in% thisAdmin$abreviation &
                                          sim$table4$ecozone %in% thisAdmin$EcoBoundaryID, ])
  } else {
    stable3 <- as.data.table(sim$table3[sim$table3$juris_id %in% thisAdmin$abreviation &
                                          sim$table3$ecozone %in% eco, ])
    stable4 <- as.data.table(sim$table4[sim$table4$juris_id %in% thisAdmin$abreviation &
                                          sim$table4$ecozone %in% eco, ])
  }

  abreviation <- c("PE", "QC", "ON", "MB", "SK", "YK", "NU", "NS")
  ## DANGER HARD CODED: if NFIS changes table 5, this will no longer be valid
  # juris_id: there are only 5/13 possible
  # these are the provinces available: AB BC NB NF NT
  # for the non match these would be the equivalent
  # "PE" - NB
  # "QC" - NB
  # "ON" - NB
  # "MB" - AB
  # "SK" - AB
  # "YK" - NT
  # "NU" - NT
  # "NS" - NB
  if (any(thisAdmin$abreviation %in% abreviation)) {
    t5abreviation <- c("NB", "NL", "NL", "AB", "AB", "NT", "NT", "NB")
    abreviationReplace <- data.table(abreviation, t5abreviation)
    # replace the abbreviations and select
    thisAdmin5 <- merge(abreviationReplace, thisAdmin)
    thisAdmin5[, c("abreviation", "t5abreviation") := list(t5abreviation, NULL)]
    stable5.2 <- as.data.table(sim$table5[sim$table5$juris_id %in% thisAdmin5$abreviation, ])
    stable5 <- stable5.2[ecozone %in% thisAdmin$EcoBoundaryID, ]
  } else {
    stable5.2 <- as.data.table(sim$table5[sim$table5$juris_id %in% thisAdmin$abreviation, ])
    stable5 <- stable5.2[ecozone %in% thisAdmin$EcoBoundaryID, ]
  }
  # This second "if-statement" is to catch is the "no-ecozone" match
  ### THIS NEEDS TO BE TESTED
  if (nrow(stable5.2) > 0) {
    stable5 <- stable5.2[ecozone %in% thisAdmin$EcoBoundaryID, ]
  } else {
    stop(
      "There are no matches found for the parameters needed to execute the Boudewyn models.",
      "Please manually find matches for table 5."
    )
  }

  if (nrow(stable5) < 1) {
    stop("There is a problem finding a parameter match in table 5.")
  }

  if (any(eco %in% ecoNotInT)) {
    stable6 <- as.data.table(sim$table6[sim$table6$juris_id %in% thisAdmin$abreviation &
                                          sim$table6$ecozone %in% thisAdmin$EcoBoundaryID, ])
    stable7 <- as.data.table(sim$table7[sim$table7$juris_id %in% thisAdmin$abreviation &
                                          sim$table7$ecozone %in% thisAdmin$EcoBoundaryID, ])
  } else {
    stable6 <- as.data.table(sim$table6[sim$table6$juris_id %in% thisAdmin$abreviation &
                                          sim$table6$ecozone %in% eco, ])
    stable7 <- as.data.table(sim$table7[sim$table7$juris_id %in% thisAdmin$abreviation &
                                          sim$table7$ecozone %in% eco, ])
  }
  # END reducing Biomass model parameter tables -----------------------------------------------

  # Read-in user provided meta data for growth curves. This could be a complete
  # data frame with the same columns as gcMetaEg.csv OR is could be only curve
  # id and species. This format is necessary to process the curves and use the
  # resulting increments
  gcMeta <- sim$gcMeta
  # gcMeta <- merge.data.table(gcMeta,landRSpecies, by = "canfi_species")
  # gcMeta[, species := NULL]
  # setnames(gcMeta, "name", "species")
  gcMeta2 <- gcMeta[, .(gcids, canfi_species)]
  
  if (nrow(gcMeta2) == length(which(gcMeta$canfi_species %in% sim$canfi_species$canfi_species))) {
    spsMatch <- sim$canfi_species[
      , which(canfi_species %in% gcMeta2$canfi_species),
      .(canfi_species, genus, name, forest_type_id)
    ]
    spsMatch[, V1 := NULL]
    names(spsMatch) <- c("canfi_species", "genus", "species", "forest_type_id")
    setkey(gcMeta2, canfi_species)
    setkey(spsMatch, canfi_species)
    gcMeta3 <- merge(gcMeta2, spsMatch) # I do not think the order of the columns matter
    gcMeta <- gcMeta3
  }
  
  
  setkey(gcMeta, gcids)
  # if (!unique(unique(userGcM3$gcids) == unique(gcMeta$gcids))) {
  #   stop("There is a missmatch in the growth curves of the userGcM3 and the gcMeta")
  # }

  # assuming gcMeta has now 6 columns, it needs a 7th: spatial_unit_id. This
  # will be used in the convertM3biom() fnct to link to the right ecozone
  # and it only needs the gc we are using in this sim.

  gcThisSim <- unique(sim$spatialDT[,.(gcids, spatial_unit_id, ecozones)])
  setkey(gcThisSim, gcids)
  setkey(gcMeta, gcids) ## changed from gcMeta to riaGcMeta
  gcMeta <- merge(gcMeta, gcThisSim) ## changed from gcMeta to riaGcMeta # adds ecozone

  setkey(gcMeta, gcids)
  setkey(userGcM3, gcids)

  if (isFALSE(c("gcids", "species") %in% colnames(gcMeta))) {
    stop("Curve ID or species is missing from gcMeta")
  }

  ################
  warning("Modifying canfi_species 1211 ecozone to 1203") ##TODO: why do we do this?
  gcMeta[canfi_species == 1211, canfi_species := 1203]

  sim$gcMetaAllCols <- gcMeta

  # START processing curves from m3/ha to tonnes of C/ha then to annual increments
  # per above ground biomass pools -------------------------------------------

  # 1. Calculate the translation (result is cumPools or "cumulative AGcarbon pools")

  # Matching is 1st on species, then on gcId which gives us location (admin,
  # spatial unit and ecozone)
  fullSpecies <- unique(gcMeta$species) ## RIA: change this to the canfi_sps or match??
  # gcMeta <- unique(gcMeta[,.(gcids, canfi_species, genus, species, forest_type_id)])

  cumPools <- Cache(cumPoolsCreate, fullSpecies, gcMeta, userGcM3,
                             stable3, stable4, stable5, stable6, stable7, thisAdmin)
  
  # curveID are the columns use to make the unique levels in the factor gcids.
  # These factor levels are the link between the pixelGroups and the curve to be
  # use to growth their AGB.
  curveID <- c("gcids") ##TODO: remove hardcode when dataPrep is updated 
  if (!is.null(sim$level3DT)) {
    gcidsLevels <- levels(sim$level3DT$gcids)
    gcids <- factor(gcidsCreate(cumPools[, ..curveID]))
  } else {
    gcids <- factor(gcidsCreate(cumPools[, ..curveID]))
  }
  set(cumPools, NULL, "id", gcids)
  set(cumPools, NULL, "gcids", gcids)

  cbmAboveGroundPoolColNames <- "totMerch|fol|other"
  colNames <- grep(cbmAboveGroundPoolColNames, colnames(cumPools), value = TRUE)

  # 2. MAKE SURE THE PROVIDED CURVES ARE ANNUAL
  ### if not, we need to extrapolate to make them annual
  minAgeId <- cumPools[,.(minAge = max(0, min(age) - 1)), by = "gcids"]
  fill0s <- minAgeId[,.(age = seq(from = 0, to = minAge, by = 1)), by = "gcids"]
  # might not need this
  length0s <- fill0s[,.(toMinAge = length(age)), by = "gcids"]
  # these are going to be 0s
  carbonVars <- data.table(gcids = unique(fill0s$gcids),
                                    totMerch = 0,
                                    fol = 0,
                                    other = 0 )

  fiveOf7cols <- fill0s[carbonVars, on = "gcids"]
  otherVars <- cumPools[,.(id = unique(id), ecozone = unique(ecozone)), by = "gcids"]
  add0s <- fiveOf7cols[otherVars, on = "gcids", allow.cartesian = TRUE]
  cumPoolsRaw <- rbind(cumPools,add0s)
  set(cumPoolsRaw, NULL, "age", as.numeric(cumPoolsRaw$age))
  setorderv(cumPoolsRaw, c("gcids", "age"))


  # 3. Plot the curves that are directly out of the Boudewyn-translation
  # Usually, these need to be, at a minimum, smoothed out.
    figPath <- file.path(outputPath(sim), "CBM_vol2biomass_figures")
    dir.create(figPath, recursive = TRUE, showWarnings = FALSE)

  # plotting and save the plots of the raw-translation in the sim$ don't really
  # need this b/c the next use of m3ToBiomPlots fnct plots all 6 curves, 3
  # raw-translation and 3-smoothed curves resulting from the Chapman-Richards
  # parameter finding in the cumPoolsSmooth fnct. Leaving these lines here as
  # exploration tools.
  # if (!is.na(P(sim)$.plotInitialTime))
  sim$plotsRawCumulativeBiomass <- m3ToBiomPlots( inc = cumPoolsRaw,
                                                  path = figPath,
                                                  filenameBase = "rawCumBiomass_")

  # Fixing of non-smooth curves

  cumPoolsClean <- cumPoolsSmooth(cumPoolsRaw
                                  ) |> Cache()

  # a[, totMerch := totMerchNew]
  if (!is.na(P(sim)$.plotInitialTime))
    figs <- Cache(m3ToBiomPlots, inc = cumPoolsClean,
                path = figPath,
                filenameBase = "cumPools_smoothed_postChapmanRichards"
                ) |> Cache()
  set(cumPoolsClean, NULL, colNames, NULL)
  colNamesNew <- grep(cbmAboveGroundPoolColNames, colnames(cumPoolsClean), value = TRUE)
  setnames(cumPoolsClean, old = colNamesNew, new = colNames)


  # 4. Calculating Increments
  incCols <- c("incMerch", "incFol", "incOther")
  cumPoolsClean[, (incCols) := lapply(.SD, function(x) c(NA, diff(x))), .SDcols = colNames,
                by = eval("gcids")]
  colsToUse33 <- c("age", "gcids", incCols)
  rawIncPlots <- Cache(m3ToBiomPlots, inc = cumPoolsClean[, ..colsToUse33],
                       path = figPath,
                       title = "Smoothed increments merch fol other by gc id",
                       filenameBase = "Increments")
  message(crayon::red("User: please inspect figures of the raw and smoothed translation of your growth curves in: ",
          figPath))


  sim$cumPoolsClean <- cumPoolsClean

  colsToUseForestType <- c("forest_type_id", "gcids") 
  
  if (!is.null(sim$level3DT)) {
    gcidsLevels <- levels(sim$level3DT$gcids)
    gcids <- factor(gcidsCreate(gcMeta[, ..curveID]))
  } else {
    gcids <- factor(gcidsCreate(gcMeta[, ..curveID]))
  }
  set(gcMeta, NULL, "gcids", gcids)
  
  forestType <- gcMeta[, ..colsToUseForestType]
  #       #FYI:
  #       # cbmTables$forest_type
  #       # id           name
  #       # 1  1       Softwood
  #       # 2  2      Mixedwood
  #       # 3  3       Hardwood
  #       # 4  9 Not Applicable

  setkeyv(forestType, "gcids")
  cumPoolsClean <- cumPoolsClean[unique(forestType), on = "gcids"]
  ## this is how it was done in the old RIA version.
  # swCols <- c("swmerch", "swfol", "swother")
  # hwCols <- c("hwmerch", "hwfol", "hwother")
  #
  # totalIncrementsSmooth <- cumPoolsClean[forest_type_id == 1, (swCols) := list((incMerch), (incFol), (incOther))]
  # totalIncrementsSmooth <- totalIncrementsSmooth[forest_type_id == 3, (hwCols) := list((incMerch), (incFol), (incOther))]
  # totalIncrementsSmooth[is.na(totalIncrementsSmooth)] <- 0
  # outCols <- c("incMerch", "incFol", "incOther", "forest_type_id")
  # incCols <- c(swCols, hwCols)
  # totalIncrementsSmooth[, (outCols) := NULL]
  # increments <- totalIncrementsSmooth[, (incCols) := list(
  #   swmerch / 2, swfol / 2,
  #   swother / 2, hwmerch / 2, hwfol / 2, hwother / 2
  # )]
  # setorderv(increments, c("gcids", "age"))
  #
  # incColKeep <- c("id", "age", incCols)
  # set(increments, NULL, "id", as.numeric(increments[["gcids"]]))
  # set(increments, NULL, setdiff(colnames(increments), incColKeep), NULL)
  # setcolorder(increments, incColKeep)
  #
  ## this is how it is done in SK, will need to see which is best
  outCols <- c("id", "ecozone", "totMerch", "fol", "other")
  cumPoolsClean[, (outCols) := NULL]
  keepCols <- c("age", "gcids", "merch_inc", "foliage_inc", "other_inc", "forest_type_id")
  incCols <- c("merch_inc", "foliage_inc", "other_inc")
  setnames(cumPoolsClean,names(cumPoolsClean),
           keepCols)
  increments <- cumPoolsClean[, (incCols) := list(
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

  # ! ----- STOP EDITING ----- ! #

  return(invisible(sim))
}

.inputObjects <- function(sim) {
  # Any code written here will be run during the simInit for the purpose of creating
  # any objects required by this module and identified in the inputObjects element of defineModule.
  # This is useful if there is something required before simulation to produce the module
  # object dependencies, including such things as downloading default datasets, e.g.,
  # downloadData("LCC2005", modulePath(sim)).
  # Nothing should be created here that does not create a named object in inputObjects.
  # Any other initiation procedures should be put in "init" eventType of the doEvent function.
  # Note: the module developer can check if an object is 'suppliedElsewhere' to
  # selectively skip unnecessary steps because the user has provided those inputObjects in the
  # simInit call, or another module will supply or has supplied it. e.g.,
  # if (!suppliedElsewhere('defaultColor', sim)) {
  #   sim$map <- Cache(prepInputs, extractURL('map')) # download, extract, load file from url in sourceURL
  # }

  # cacheTags <- c(currentModule(sim), "function:.inputObjects") ## uncomment this if Cache is being used
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")
  cacheTags <- c(currentModule(sim), "function:.inputObjects")

  if (!suppliedElsewhere("curveID", sim)) {
    sim$curveID <- c("gcids", "ecozones")
  }

  # 1. tables from Boudewyn
  # these are all downloaded from the NFIS site. The NFIS however, changes the
  # tables and seems to forget parameter coumns at times. So, we added a check to
  if (!suppliedElsewhere("table3", sim)) {
    sim$table3 <- prepInputs(url = extractURL("table3"),
                             fun = "data.table::fread",
                             destinationPath = dPath,
                             overwrite = FALSE,
                             #purge = 7,
                             filename2 = "appendix2_table3.csv")
    # these are the columns needed in the functions for calculating biomass
    t3hasToHave <- c("juris_id", "ecozone", "canfi_species", "genus", "species",
                     "a", "b", "volm")
    if(!length(which(colnames(sim$table3) %in% t3hasToHave)) == length(t3hasToHave)){
      message(
        "The parameter table (appendix2_table3) does not have the expected number of columns. ",
        "This means parameters are missing. The default (older) parameter file will be used instead."
      )
      sim$table3 <- fread(file.path("modules","CBM_vol2biomass_RIA","data","appendix2_table3.csv"))
    }
  }
  if (!suppliedElsewhere("table4", sim)) {
    sim$table4 <- prepInputs(url = extractURL("table4"),
                             fun = "data.table::fread",
                             destinationPath = dPath,
                             overwrite = FALSE,
                             #purge = 7,
                             filename2 = "appendix2_table4.csv")
     t4hasToHave <- c("juris_id", "ecozone", "canfi_species", "genus", "species",
                     "a", "b", "k", "cap", "volm")
    if(!length(which(colnames(sim$table4) %in% t4hasToHave)) == length(t4hasToHave)){
      message(
        "The parameter table (appendix2_table4) does not have the expected number of columns. ",
        "This means parameters are missing. The default (older) parameter file will be used instead."
      )
    }
  }
  if (!suppliedElsewhere("table5", sim)) {
    sim$table5 <- prepInputs(url = extractURL("table5"),
                             fun = "data.table::fread",
                             destinationPath = dPath,
                             overwrite = FALSE,
                             #purge = 7,
                             filename2 = "appendix2_table5.csv")

    t5hasToHave <- c("juris_id", "ecozone", "canfi_genus", "genus", "a", "b", "k",
                     "cap", "volm")
    if(!length(which(colnames(sim$table5) %in% t5hasToHave)) == length(t5hasToHave)){
      message(
        "The parameter table (appendix2_table5) does not have the expected number of columns. ",
        "This means parameters are missing. The default (older) parameter file will be used instead."
      )
    }
  }
  if (!suppliedElsewhere("table6", sim)) {
    sim$table6 <- prepInputs(url = extractURL("table6"),
                             fun = "data.table::fread",
                             destinationPath = dPath,
                             overwrite = FALSE,
                             #purge = 7,
                             filename2 = "appendix2_table6_v2.csv")
#    sim$table6 <- fread("https://nfi.nfis.org/resources/biomass_models/appendix2_table6.csv",
#                        fill = TRUE)
    t6hasToHave <- c("juris_id", "ecozone", "canfi_species", "a1", "a2", "a3", "b1", "b2", "b3",
                     "c1", "c2", "c3" )
    if(!length(which(colnames(sim$table6) %in% t6hasToHave)) == length(t6hasToHave)){
      message(
        "The parameter table (appendix2_table6) does not have the expected number of columns. ",
        "This means parameters are missing. The default (older) parameter file will be used instead."
      )
 #     sim$table6 <- fread(file.path("modules","CBM_vol2biomass_RIA","data","appendix2_table6.csv"))
      ## TODO: use url to googleDrive (G:\userDataDefaultsCBM_SK)
    }
  }
  if (!suppliedElsewhere("table7", sim)) {
    sim$table7 <- prepInputs(url = extractURL("table7"),
                             fun = "data.table::fread",
                             destinationPath = dPath,
                             overwrite = FALSE,
                             #purge = 7,
                             filename2 = "appendix2_table7.csv")

    t7hasToHave <- c("juris_id", "ecozone", "canfi_species", "vol_min", "vol_max", "p_sw_low",
                     "p_sb_low", "p_br_low", "p_fl_low", "p_sw_high", "p_sb_high", "p_br_high",
                     "p_fl_high")
    if(!length(which(colnames(sim$table7) %in% t7hasToHave)) == length(t7hasToHave)){
      message(
        "The parameter table (appendix2_table7) does not have the expected number of columns. ",
        "This means parameters are missing. The default (older) parameter file will be used instead."
      )
    }
  }

  if (!suppliedElsewhere("gcids", sim)) {
    ## this is where the pixelGroups and their spu eco etc.
    message("No spatial information was provided for the growth curves.
            The default values (RIA NE BC) will be used to limit the number of growth curves used.")
    sim$gcids <- c(801000, 801001, 801002, 802000, 802001, 802002, 801003, 803000,
                   801008, 803002, 802008, 801006, 802006, 802003, 803003, 803001,
                   803008, 803006, 803004, 802004, 801004, 802007, 801005, 803007,
                   802005, 801007, 803005, 4002000, 4001000, 4003000, 4001002, 4001001,
                   1601005, 4003005, 4002003, 4001003, 4002005, 4003001, 4002001,
                   1601011, 4001005, 1603005, 1603007, 1601004, 1602007, 1601002,
                   4002002, 1602002, 1602004, 1601007, 1603004, 1602009, 1603009,
                   4003002, 4003003, 1603011, 1602011, 1603002, 1602005, 1601009,
                   1601001, 1601000, 1602001, 1602000, 1603000, 1601006, 1602006,
                   1603001, 1603006, 4001006, 4002006, 4003006, 1601010, 1603010,
                   2401000, 2401003, 2401005, 2401002, 2402000, 2402003, 2403003,
                   2402001, 2402004, 2403001, 2401001, 2401006, 1602010, 2401004,
                   2403004, 4002004, 4001004, 4003004, 1601003, 2403000, 1602003,
                   2402007, 1601008, 1602008, 2401007, 2402005, 2403005, 1603003,
                   1603008, 2402002, 2403006, 2402006, 2403002, 4103005, 4101000,
                   4102000, 4103003, 4103006, 4101003, 4101006, 4102003, 4102005,
                   4101005, 4101008, 4103000, 4101009, 4102007, 4101007, 4103008,
                   4102009, 4103007, 4103009, 4102002, 4103002, 4101002, 4102006,
                   2403007, 4103001, 4102008, 4102001, 4101001, 4102004, 4103004,
                   4101004)
  }

  if (!suppliedElsewhere("ecozones", sim)) {
    message("No spatial information was provided for the growth curves.
            The default values (RIA NE BC) will be used to determine which ecozones these curves are in.")
    sim$ecozones <- c(4, 12, 9, 14)
  }
  if (!suppliedElsewhere("spatialUnits", sim)) {
    message("No spatial information was provided for the growth curves.
            The default values (RIA NE BC) will be used to determine which CBM-spatial units these curves are in.")
    sim$spatialUnits <- c(38, 40, 39, 42)
  }

  # 1. growth and yield information
  # userGcM3 and userGcM3File, these files are the m3/ha and age info by growth
  # curve ID, columns should be GrowthCurveComponentID	Age	MerchVolume
  ## TODO add a data manipulation to adjust if the m3 are not given on a yearly basis
  if (!suppliedElsewhere("userGcM3", sim)) {

    if (!suppliedElsewhere("userGcM3File", sim)) {
      sim$userGcM3File <- extractURL("userGcM3")
    }

      sim$userGcM3 <- prepInputs(url = sim$userGcM3File,
                                 fun = "data.table::fread",
                                 destinationPath = dPath,
                                 #purge = 7,
                                 filename2 = "curve_points_table.csv")

      # message(
      #   "User has not supplied growth curves (m3 by age or the file name for the growth curves). ",
      #   "The default will be used which is for a region in Saskatchewan."
      # )
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
                                 destinationPath = dPath,
                                 #purge = 7,
                                 filename2 = "au_table.csv")

      # message(
      #   "User has not supplied growth curves (m3 by age or the file name for the growth curves). ",
      #   "The default will be used which is for a region in Saskatchewan."
      # )
  }

  # 4. cbmAdmin: this is needed to match species and parameters. Boudewyn et al 2007
  # abbreviation and cbm spatial units and ecoBoundnary id is provided with the
  # adminName to avoid confusion.
  if (!suppliedElsewhere("cbmAdmin", sim)) {
    sim$cbmAdmin <-  prepInputs(url = extractURL("cbmAdmin"),
                                fun = "data.table::fread",
                                destinationPath = dPath,
                                #purge = 7,
                                filename2 = "cbmAdmin.csv")
  }

  # 5. canfi_species: for the BOudewyn parameters, the species have to be matched
  # with the ones in the Boudewyn tables. The choices HAVE to be one of these.
  # This contains three columns, canfi_species, genus and species form the
  # publication and I added (manually) one more: forest_type_id. That variable is a CBM-CFS3
  # indicator as follows:
  # cbmTables$forest_type
  # id           name
  # 1  1       Softwood
  # 2  2      Mixedwood
  # 3  3       Hardwood
  # 4  9 Not Applicable
  if (!suppliedElsewhere("canfi_species", sim)) {
    sim$canfi_species <- prepInputs(url = extractURL("canfi_species"),
                                    fun = "data.table::fread",
                                    destinationPath = dPath,
                                    #purge = 7,
                                    filename2 = "canfi_species.csv")
  }

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}
