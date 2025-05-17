= C Implementation of Myers' Bit-parallel Algorithm <app_myers>

```C
int32_t myers1999(char *s1, int32_t len1, char *s2, int32_t len2) {

    uint256_t Peq[256];
    uint256_t Eq, Xv, Xh, Ph, Mh, Pv, Mv, Last;
    int32_t i;
    int32_t Score = len2;

    memset(Peq, 0, sizeof(Peq));

    for (i = 0; i < len2; i++)
        Peq[(uint8_t)s2[i]] |= (uint256_t)1 << i;

    Mv = 0;
    Pv = (uint256_t)-1;
    Last = (uint256_t)1 << (len2 - 1);

    for (i = 0; i < len1; i++) {
        Eq = Peq[(uint8_t)s1[i]];

        Xv = Eq | Mv;
        Xh = (((Eq & Pv) + Pv) ^ Pv) | Eq;

        Ph = Mv | ~(Xh | Pv);
        Mh = Pv & Xh;

        if (Ph & Last)
            Score++;
        if (Mh & Last)
            Score--;

        Ph = (Ph << 1) | 1;
        Mh = (Mh << 1);

        Pv = Mh | ~(Xv | Ph);
        Mv = Ph & Xv;
    }

    return Score;
}
```
