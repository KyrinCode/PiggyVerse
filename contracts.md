### 合约地址

```
PiggyVerse: 0x16F7B599411f1eaF3D7EA52398fCbCD405D96efa
PiggyERC20: 0xfCa80bE9916feA07b17A5b827Ea97231f56b4Ca4

PiggyAwards: 0x4a708240F4bEBD4F3028FC1338E986f402A91544
PiggyChecklist: 0x3387319481527E2437Ee82FFe0e49F15111842d3
PiggyDiaries: 0x9028A8860c8C2497691c41a7d6a65Fe9AAE84Cd1
PiggyMemories: 0x314BB9970117a6AbC4985789454D22261Cc3Af6c
PiggyTasks: 0xAc6d460626c4D37044e5d182e11366edBdC3B007
```

#### Piggy(PP) 代币

| Read                         | 说明                        |
| ---------------------------- | --------------------------- |
| 2. balanceOf(owner)          | 查看余额                    |
| 1. allowance(owner, spender) | 查看授权给 spender 多少额度 |
| 9. totalSupply               | 查看总发行量                |

| Write                      | 说明                |
| -------------------------- | ------------------- |
| 7. transfer(to, value)     | 转账                |
| 2. burn(value)             | 销毁                |
| 1. approve(spender, value) | 授权给 spender 额度 |

#### PiggyAwards

| Read                     | 说明                                      |
| ------------------------ | ----------------------------------------- |
| 7. getToEffieOnSaleIds   | 查看给 Effie 的待售奖励 id 列表           |
| 12. getToKyrinOnSaleIds  | 查看给 Kyrin 的待售奖励 id 列表           |
| 8. getToEffieSaledIds    | 查看给 Effie 的已售奖励 id 列表           |
| 13. getToKyrinSaledIds   | 查看给 Kyrin 的已售奖励 id 列表           |
| 4. getToEffieCanceledIds | 查看给 Effie 的但已下架的待售奖励 id 列表 |
| 9. getToKyrinCanceledIds | 查看给 Kyrin 的但已下架的待售奖励 id 列表 |
| 3. getSaleById(saleId)   | 通过 saleId 获取奖励信息                  |
| 6. getToEffieIds         | 查看给 Effie 的奖励 id 列表               |
| 11. getToKyrinIds        | 查看给 Kyrin 的奖励 id 列表               |
| 5. getToEffieDoneIds     | 查看给 Effie 的已消耗奖励 id 列表         |
| 10. getToKyrinDoneIds    | 查看给 Kyrin 的已消耗奖励 id 列表         |
| 2. getAwardById(awardId) | 通过 awardId 获取奖励信息                 |

以 Effie 向 Kyrin 发布奖励为例：

| Write                                    | 说明                                                         |
| :--------------------------------------- | :----------------------------------------------------------- |
| 2. addOnSale(name, cnt, value, longTerm) | Effie 发布待售奖励，发布后可在 getToKyrinOnSaleIds 中查看 saleId。 |
| 7. deleteOnSale(saleId)                  | Effie 删除待售奖励，彻底删除内容，仅适用于未被购买过的待售奖励。 |
| 4. cancelOnSale(saleId)                  | Effie 下架待售奖励，保留内容，但不再有效，下架后可在 getToKyrinCanceledIds 中查看 saleId。 |
| 6. changeOnSaleLongTerm(saleId)          | Effie 更改待售奖励是否是长期待售，长期待售的奖励可以反复购买。 |
| 3. buyOnSale(saleId)                     | Kyrin 购买待售奖励，购买前需要在代币合约给PiggyAwards合约授权（approve）充足的额度，购买后可在 getToKyrinSaledIds 中查看，并自动铸造奖励，可在 getToKyrinIds中查看。 |
| 1. addAward(name, cnt)                   | Effie 赠予奖励，赠予后可在 getToKyrinIds 中查看 awardId。    |
| 8. finishAward(awardId)                  | Effie 完成奖励，完成后可在 getToKyrinDoneIds 中查看 awardId。 |
| 5. changeAwardCnt(awardId, cnt)          | Effie 改变奖励数量。                                         |

#### PiggyTasks

| Read                      | 说明                                  |
| ------------------------- | ------------------------------------- |
| 38. getToEffieIds         | 查看给 Effie 的任务 id 列表           |
| 42. getToKyrinIds         | 查看给 Kyrin 的任务 id 列表           |
| 37. getToEffieFinishedIds | 查看给 Effie 的已完成任务 id 列表     |
| 41. getToKyrinFinishedIds | 查看给 Kyrin 的已完成任务 id 列表     |
| 39. getToEffieVerifiedIds | 查看给 Effie 的已审核通过任务 id 列表 |
| 43. getToKyrinVerifiedIds | 查看给 Kyrin 的已审核通过任务 id 列表 |
| 36. getToEffieCanceledIds | 查看给 Effie 但已下架的任务 id 列表   |
| 40. getToKyrinCanceledIds | 查看给 Kyrin 但已下架的任务 id 列表   |
| 35. getTaskById(taskId)   | 通过 taskId 获取任务信息              |

以 Effie 向 Kyrin 发布任务为例：

| Write                              | 说明                                                         |
| ---------------------------------- | ------------------------------------------------------------ |
| 26. addTask(name, value, longTerm) | Effie 发布任务，发布后可在 getToKyrinIds 中查看 taskId。     |
| 30. deleteTask(taskId)             | Effie 删除任务，彻底删除内容，仅适用于未被完成过的任务。     |
| 27. cancelTask(taskId)             | Effie 下架任务，保留内容，但不再有效，下架后可在 getToKyrinCanceledIds 中查看 taskId。 |
| 28. changeTaskLongTerm(taskId)     | Effie 更改任务是否是长期可做，长期任务可做可以反复完成。     |
| 31. finishTask(taskId)             | Kyrin 表示完成任务，完成后可在 getToKyrinFinishiedIds 中查看 taskId。 |
| 32. verifyTask(taskId)             | Effie 审核任务是否完成，完成则可在 getToKyrinVerifiedIds 中查看 taskId，未完成则 taskId 回到 getToKyrinIds 中。 |
| 29. checkin                        | 每日早 8 点后仅一次打卡机会，奖励 2PP。                      |

#### PiggyDiaries

| Read                                 | 说明                                            |
| ------------------------------------ | ----------------------------------------------- |
| 20. getByEffieIds                    | 查看 Effie 写的日记 id 列表                     |
| 22. getByKyrinIds                    | 查看 Kyrin 写的日记 id 列表                     |
| 21. getByEffieLockedIds              | 查看 Effie 写的加密日记 id 列表                 |
| 23. getByKyrinLockedIds              | 查看 Kyrin 写的加密日记 id 列表                 |
| 25. getDiaryById(diaryId)            | 通过 diaryId 获取日记信息                       |
| 24. getCommentById(commentId)        | 通过 commentId 获取评论信息                     |
| 19. encodeDiary(text, secret)        | 将日记明文 text 通过密钥 secret 加密得到密文 e  |
| 26. viewLockedDiary(diaryId, secret) | 通过密钥 secret 查看 diaryId 对应加密日记的内容 |

以 Effie 发布日记为例：

| Write                                          | 说明                                                         |
| ---------------------------------------------- | ------------------------------------------------------------ |
| 13. addDiary(text)                             | Effie 发布公开日记，发布后可在 getByEffieIds 中查看 diaryId。 |
| 18. modifyDiaryDate(diaryId, year, month, day) | Effie 修改日记时间（公开或加密日记均可）。                   |
| 19. modifyDiaryText(diaryId, text)             | Effie 修改公开日记内容。                                     |
| 17. deleteDiary(diaryId)                       | Effie 删除日记，彻底抹除内容（公开或加密日记均可）。         |
| 15. commentDiary(diaryId, text)                | Effie 或 Kyrin 评论日记。                                    |
| 16. deleteComment(diaryId, commentId)          | 评论作者删除 diaryId 对应日记的 commentId 评论。             |
| 20. tipDiary(diaryId)                          | Kyrin 对公开日记打赏，系统为 Effie 奖励 3PP，仅限 1 次，加密日记解锁公开后不可再打赏。 |
| 14. addLockedDiary(e)                          | Effie 发布加密日记，发布之前通过 encodeDiary 得到密文 e，发布后可在 getByEffieLockedIds 中查看 diaryId。 |
| 21. unlockDiary(diaryId, secret)               | Kyrin 解锁加密日记，拿到 secret 后首先通过 viewLockedDiary 验证再解锁，解锁后密文会被明文覆盖，消耗 3PP，其中 1PP会转给 Effie。 |

