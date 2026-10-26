# Verified runtime — Steam1.09/build12996889

MeterOnHead2_C:Tick under /Game/MainContent/Template/UMG/MeterOnHead2. ownAvatar validates GenesisCharacter; skip player controlled. CurVals/MaxVals/CurColorClasses real arrays use HP index2 in observed Lua runtime; adapter identifies red color class and matches HPBar.Percent, does not blindly assume full bars distinguish health. Observed max HP252/588/420 give widths90/112/102. High HP is not proof of boss status.

Actual large floating digits: /Game/MainContent/Template/UMG/HudUmg.HudUmg_C, dedicated root CanvasPanel contains20 TextBlocks DamageDigits0..19. Hide that root opacity after verified parent relationship; animations remain. MeterOnHead2.DamageText stayed9876; HUDDamageTip_BP had no observed combat instances. Hiding those alone did not solve the symptom. Production no longer scans every numeric text block.

Garamond asset /Game/Fonts/EBGaramond-SemiBold_Font.EBGaramond-SemiBold_Font is UFont, Default typeface references EBGaramond-SemiBold FontFace. FontObject/TypefaceFontName/Size/OutlineSettings set explicitly, no global font change. User accepted size12/outline1.



Historical raw evidence remains in the ignored root .local/evidence archive. Do not copy proprietary dumps into this folder.
