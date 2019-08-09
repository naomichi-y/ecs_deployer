#!/usr/bin/env ruby
# encoding: UTF-8

$: << File.dirname(__FILE__)
$oj_dir = File.dirname(File.expand_path(File.dirname(__FILE__)))
%w(lib ext).each do |dir|
  $: << File.join($oj_dir, dir)
end

#require 'json'
require 'oj'

Oj.mimic_JSON

obj = {
  ab: {
    cbbb: {
      tilbeb: [
        {
          coob: {
            uijwts: [
              {
                prrrrr: {
                  yakj: "pvebbx",
                  lbhqy: {
                    uhyw: {
                      uijwts: [
                        {
                          jangi: {
                            ubentg7haineued8atnr8w: {
                              abc: "uejdncbncnamnasdasdasdasd",
                              cde: "skfjskdfjskdfjsdkfjsdkfjs"
                            }
                          }
                        }
                      ]
                    }
                  }
                }
              },
              {
                kdncg: {
                  lvbnt8b9ounv: {
                    qk: 9
                  }
                }
              }
            ],
            jenfjbhe: {}
          }
        }
      ]
    }
  },
  ijbh: {
    jsnbrpbnunt: {
      b88dibalbvp: {
        mnbvd: "9uhbqlpiev"
      }
    },
    ncnwkl: {
      ksdfsf: {
        mjln: "mnklkn"
      },
      kbrh: {
        sdfn83nnalbmgnansdd: {
          uijwts: {
            ibha: {
              uijwts: [
                {
                  lnrbf: {
                    nbvtmqbhap9ebeb7btnnaw: {
                      ksb: "sdfksdfjsdfsb39242dnasddd",
                      mnm: "1293dsfnsdmfnsdfsd,fmnsd,"
                    }
                  }
                }
              ]
            }
          },
          kbrh: {
            bo8libts: {
              nag40n: {
                kyen: "sdfasnc92nsn"
              },
              kbrh: {
                nbwyu26snfcbajsdkj8: {
                  uijwts: {
                    mdfnkjsdd: {}
                  },
                  kbrh: {
                    kneahce: {
                      uijwts: {
                        kwnb: {
                          uijwts: [
                            {
                              fhfd: {
                                sfasdnfmasndfamsdnfajsmdf: false
                              }
                            }
                          ],
                          asdfsdff: [
                            {
                              cwdf: {
                                sddlkfajsdkfjabskdfjalsdkfjansdkfjf: ""
                              }
                            },
                            {
                              bsdj: {
                                sdfsjdlfkasy8kljsfsdf83jlkjfals: true
                              }
                            }
                          ]
                        }
                      },
                      kbrh: {
                        sdfsdfsddfk: {
                          uijwts: {
                            sdfsd: {
                              sdfsadf89mnlrrrqurqwvdnff: {
                                "kj": 8
                              }
                            }
                          },
                          kbrh: {
                            dkdjd: {
                              dfeteu: {
                                sdfd: "sdfasdfjlkjslrsdbb"
                              },
                              kbrh: {
                                sdfskjdfldk: {
                                  buqpen: {
                                    kjlkj: {
                                      sdflskdjfalsdkrjalwkjfsrlfjasdf: {
                                        sd: 0
                                      }
                                    }
                                  },
                                  kbrh: {
                                    sdfksljdlfksdfl: {
                                      sdfsdkfjssd: {
                                        ksdjf: "sdflsdkfjasdkaufs;ldkfjsdlf",
                                        sdfsdfsl: [5]
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

#Oj.dump(obj)
JSON.pretty_generate(obj)
#JSON.generate(obj)
