say [+]
(1..999).map:
{
   ($_ %% 3 or $_ %% 5) ?? $_ !! 0
}
