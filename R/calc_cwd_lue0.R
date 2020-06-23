calc_cwd_lue0 <- function(df, inst, do_plot = FALSE){  

  ## SiF vs CWD: ALEXI/WATCH-WFDEI------------------------------------------
  ## retain only data from largest instances of each year
  biginstances <- inst %>% 
    mutate(year = lubridate::year(date_start)) %>% 
    group_by(year) %>% 
    dplyr::filter(deficit == max(deficit)) %>% 
    pull(iinst)

  df <- df %>% 
    dplyr::filter(iinst %in% biginstances)
  
  nlue <- df %>%
    summarise(nlue = sum(!is.na(lue))) %>%
    pull(nlue)

  if (nlue > 10){
    ## get linear fit with outliers
    linmod <- try(lm(lue ~ deficit, data = df))
    if (class(linmod) != "try-error"){

      idx_drop <- which(is.na(remove_outliers(linmod$residuals, coef = 1.5)))
      df$lue[idx_drop] <- NA
      
      ## git linear fit without outliers
      linmod <- try(lm(lue ~ deficit, data = df))
      
      if (class(linmod) != "try-error"){

        ## test: is slope negative?
        slope_lue <- coef(linmod)["deficit"]
        is_neg <- slope_lue < 0.0
        
        if (is_neg){
          ## test: is slope significantly (5% level) different from zero (t-test)?
          is_sign <- coef(summary(linmod))["deficit", "Pr(>|t|)"] < 0.05
          if (is_sign){
            ## get x-axis cutoff
            lue0 <- - coef(linmod)["(Intercept)"] / coef(linmod)["deficit"]
            df_fit <- tibble(y = predict(linmod, newdata = df), x = df$deficit)
          } else {
            lue0 <- NA
          }
        } else {
          is_sign <- FALSE
          lue0 <- NA
        }

      } else {
        is_sign <- FALSE
        lue0_fluxnet <- NA
        slope_lue <- NA
      }
      
    } else {
      is_sign <- FALSE
      lue0 <- NA
      slope_lue <- NA
    }
    
    ## get exponential fit
    expmod <- try( nls(lue ~ a * exp(k * deficit), data = df, start = list(a = 0.1, k = 1/50)) )
    if (class(expmod) != "try-error"){
      
      df_coef <- summary(expmod) %>% coef()
      
      ## test: is slope negative?
      k_lue <- df_coef["k", "Estimate"]
      is_neg_exp <- k_lue < 0
      
      if (is_neg_exp){
        ## test: is slope significantly (5% level) different from zero (t-test)?
        is_sign_exp <- df_coef["k", "Pr(>|t|)"] < 0.05
        
        if (is_sign_exp){
          
          ## get CWD at wich LUE is at 1/2e
          lue0_exp <- -1.0/coef(expmod)["k"]   ## CWD where LUE is reduced to 1/e
          df_fit_exp <- tibble(y = predict(expmod, newdata = df), x = df$deficit)
          
        } else {
          lue0_exp <- NA
        }
      } else {
        is_sign_exp <- FALSE
        lue0_exp <- NA
        k_lue <- NA
      }
      
    } else {
      is_sign_exp <- FALSE
      lue0_exp <- NA
      k_lue <- NA
    }

    if (do_plot){
      gg <- df %>%
        mutate(iinst = as.factor(iinst)) %>%
        ggplot() +
        geom_point(aes(x = deficit, y = lue, color = iinst), alpha = 0.5) +
        labs( x = "Cumulative water deficit (mm)", y = "SiF", subtitle = "ET: ALEXI, precipitation: WATCH-WFDEI, SiF: Duveiller et al.") +
        geom_hline(yintercept = 0.0, linetype = "dotted")
      # ylim(-0.1, 0.5)
      
      if (is_sign){
        gg <- gg +
          geom_vline(xintercept = lue0, linetype = "dotted", color = 'tomato') +
          geom_line(data = df_fit, aes(x, y), col = "tomato")
      }
      if (is_sign_exp){
        gg <- gg +
          geom_vline(xintercept = lue0_exp, linetype = "dotted", color = 'royalblue') +
          geom_line(data = df_fit_exp, aes(x, y), col = "royalblue")
      }
      # if (!identical(gumbi_alexi$mod, NA)){
      #   mctXX_alexi <- gumbi_alexi$df_return %>% dplyr::filter(return_period == use_return_period) %>% pull(return_level)
      #   if (!is.na(mctXX_alexi)){
      #     gg <- gg +
      #       geom_vline(xintercept = mctXX_alexi)
      #   } else {
      #     rlang::warn(paste("No ALEXI MCT outputs for site"))
      #   }
      # } else {
      #   rlang::warn(paste("No ALEXI MCT outputs for site"))
      #   mctXX_alexi <- NA
      # }
      
    } else {
      gg <- NA
    }    

  } else {

    # rlang::inform(paste0("Not enough SiF data points for site ", sitename))
    lue0 <- NA
    slope_lue <- NA
    lue0_exp <- NA
    k_lue <- NA
    gg <- NA

  }

  return(list(lue0 = lue0, slope_lue = slope_lue, lue0_exp = lue0_exp, k_lue = k_lue, gg = gg))

}