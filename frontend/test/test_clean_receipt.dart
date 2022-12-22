import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/response.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Receipt cleanReceipt(Receipt receipt, res1, res2) {
  var result = receipt;

  List<String> discounts_swe = [
    "Prisnedsättning",
    "Rabatt",
  ];
  List<String> stopwords = ["Mottaget", "Kontokort"];

  List<ReceiptItem> items = result.items;
  //print(items);
  expect(items.length, res1);
  String ocr_text = result.ocrText;
  List<String> ocr = ocr_text.split("\n");

  List<String> cleanedOcr = [];

  for (String str in ocr) {
    //cleanedOcr.add(str.replaceAll(RegExp(r"\s+"), ""));
    cleanedOcr.add(str.trim());
  }

  for (int i = 0; i < items.length; i++) {
    String desc = items[i].itemName;
    //print(desc);
    if (desc.contains("C,kr/kg") || desc.contains("kr/kg")) {
      for (int j = 0; j < cleanedOcr.length; j++) {
        if (cleanedOcr[j].contains(items[i - 1].itemName)) {
          print("Inside ${cleanedOcr[j]}");
          items[i].itemName = cleanedOcr[j + 1];
        }
      }
    }

    for (String stopword in discounts_swe) {
      String desc = items[i].itemName;
      double amount = items[i].amount;
      if (desc.contains(stopword)) {
        items[i - 1].itemName += " $desc";
        items[i - 1].amount += amount;
        items.removeAt(i);
        i--;
      }
    }
    for (String stopword in stopwords) {
      String desc = items[i].itemName;
      if (desc.contains(stopword)) {
        items.removeAt(i);
        i--;
      }
    }
    if (double.tryParse(desc.replaceAll(",", "")) != null) {
      items.removeAt(i);
      i--;
    }
  }
  //print(double.tryParse(items[24].itemName.replaceAll(",", "")));
  //print(items);
  expect(items.length, res2);
  return result;
}

main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Successful test for sum of array
  test('test1', () {
    Receipt receipt = Receipt.fromJson(one);
    cleanReceipt(receipt, 8, 7);
  });
  test('test2', () {
    Receipt receipt = Receipt.fromJson(two);
    cleanReceipt(receipt, 30, 24);
  });
  test('test3', () {
    Receipt receipt = Receipt.fromJson(three);
    cleanReceipt(receipt, 9, 9);
  });
  test('test4', () {
    Receipt receipt = Receipt.fromJson(four);
    cleanReceipt(receipt, 13, 12);
  });
  test('test6', () {
    Receipt receipt = Receipt.fromJson(six);
    cleanReceipt(receipt, 10, 9);
  });
}

final two = {
  "ocr_type": "receipts",
  "request_id": "P_158.174.19.71_lbxir0y6_sqt",
  "ref_no": "AspDemo_1671618931784_484",
  "file_name": "IMG_20221121_164952__01.jpg",
  "request_received_on": 1671618929550,
  "success": true,
  "image_width": 1692,
  "image_height": 4453,
  "image_rotation": -0.006,
  "recognition_completed_on": 1671618932885,
  "receipts": [
    {
      "merchant_name": "Uppsala Stenhagen",
      "merchant_address": null,
      "merchant_phone": null,
      "merchant_website": null,
      "merchant_tax_reg_no": null,
      "merchant_company_reg_no": null,
      "region": null,
      "mall": null,
      "country": "US",
      "receipt_no": "A800",
      "date": "2022-11-04",
      "time": "19:15",
      "items": [
        {
          "amount": 12.90,
          "category": null,
          "description": "FUSILLI TRICOLORE",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 46.90,
          "category": null,
          "description": "ALMOND REMIX SWE/SAL",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 46.90,
          "category": null,
          "description": "MAGNUM DOUBLE GOLD",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 16.50,
          "category": null,
          "description": "PASTASAS RICOTTA",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 84.90,
          "category": null,
          "description": "SOLTORKADE TOMATER",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 29.90,
          "category": null,
          "description": "INGUINE BOLOGNESE",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 19.90,
          "category": null,
          "description": "TORK SOJASAS 500ML",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 29.80,
          "category": null,
          "description": "KOKOSMJÖLK 18%",
          "flags": "",
          "qty": 2,
          "remarks": null,
          "tags": null,
          "unitPrice": 14.90
        },
        {
          "amount": 11.90,
          "category": null,
          "description": "POTATISKLYFTOR 750G",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 125.00,
          "category": null,
          "description": "LAXFILE BIT 400G",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": -37.50,
          "category": null,
          "description": "Prisnedsättning 30,0%",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 49.90,
          "category": null,
          "description": "SPARRIS 600G",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 16.90,
          "category": null,
          "description": "DRYCK MULTIVITAMIN",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 89.90,
          "category": null,
          "description": "VÄSTERBOTTENSOST",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": -20.00,
          "category": null,
          "description": "Rabatt: VÄSTERBOTTEN",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 13.50,
          "category": null,
          "description": "KVARG NAT 500G 0,3%",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 23.50,
          "category": null,
          "description": "HUMMUS KLASSISK",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 41.90,
          "category": null,
          "description": "LAX SKIV KALLROKT",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 42.96,
          "category": null,
          "description": "kr/kg",
          "flags": "",
          "qty": 361,
          "remarks": null,
          "tags": null,
          "unitPrice": 119.00
        },
        {
          "amount": -12.89,
          "category": null,
          "description": "Prisnedsättning 30,0%",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 10.90,
          "category": null,
          "description": "MELLANMJÖLK 1L",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 14.90,
          "category": null,
          "description": "CHAMPINJONER 250G",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 3.90,
          "category": null,
          "description": "PAPPKASSE BRUN 32L",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 15.50,
          "category": null,
          "description": "TORTILLA ORI MEDIUM",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 14.90,
          "category": null,
          "description": "ISBERG FRISÉ",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 39.90,
          "category": null,
          "description": "ZUCCHINI GRON",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 5.90,
          "category": null,
          "description": "TOMAT BABYPLOMMON",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 755.57,
          "category": null,
          "description": "Mottaget Kontokort",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 745.77,
          "category": null,
          "description": "79,90665,87",
          "flags": "",
          "qty": 12.00,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 9.80,
          "category": null,
          "description": "1,967,84",
          "flags": "",
          "qty": 25.00,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        }
      ],
      "currency": "USD",
      "total": 755.57,
      "subtotal": null,
      "tax": null,
      "service_charge": null,
      "tip": null,
      "payment_method": null,
      "payment_details": null,
      "credit_card_type": "MASTER",
      "credit_card_number": "7235",
      "ocr_text":
          "    WILLY: S\n      affärsidé: Sveriges billigaste matkasse\n     Uppsala Stenhagen\n             Tfn: 018-700 99 10\n              Org: 556163-2232\n FUSILLI TRICOLORE                   12,90\n ALMOND REMIX SWE/SAL                46,90\n MAGNUM DOUBLE GOLD                  46,90\n PASTASAS RICOTTA                    16,50\n SOLTORKADE TOMATER                  84,90\n  INGUINE BOLOGNESE                  29,90\n  TORK SOJASAS 500ML                 19,90\n KOKOSMJÖLK 18%       2st*14,90      29,80\n POTATISKLYFTOR 750G                 11,90\n LAXFILE BIT 400G                   125,00\n   Prisnedsättning 30,0%            -37,50\n SPARRIS 600G                        49,90\n DRYCK MULTIVITAMIN                   16,90\n VÄSTERBOTTENSOST                     89,90\n   Rabatt: VÄSTERBOTTEN              -20,00\n KVARG NAT 500G 0,3%                  13,50\n HUMMUS KLASSISK                      23,50\n LAX SKIV KALLROKT                    41,90\n KOTLETT CA450G\n             0,361kg*119,00kr/kg      42,96\n   Prisnedsättning 30,0%             -12,89\n MELLANMJÖLK 1L                       10,90\n CHAMPINJONER 250G                    14,90\n PAPPKASSE BRUN 32L                    3,90\n TORTILLA ORI MEDIUM                   15,50\n                                       16,90\n ISBERG FRISÉ\n                                       14,90\n ZUCCHINI GRON\n                                       39,90\n TOMAT BABYPLOMMON\n                                        5,90\n PLASTKASSE VIT\n   Totalt 26 varor\n   Totalt               755,57 SEK\n Mottaget Kontokort                   755,57\n                            ****** 7235\n MASTERCARD\n                      755,57 SEK\n KOP\n Butik: 1059716       Kal 6 000 SWE 118647\n Ref: 000042105762    Term: 4/00004421\n TVR: 0020008001      AID: A0000000041010\n 2022-11-04 19:15     TSI: A800\n Persis kod\n KONTAKILOS\n  Moms%       Moms          Netto      Brutto\n 12,00       79,90         665,87      745,77\n 25,00        1,96           7,84        9,80\n         SPARA KVITTOT\n            Öppettider\n               Alla dagar 8-21\n               Välkommen åter!\n              Du betianades av\n                     Kim\n Kassa: 4/610\n                            2022-11-04 19:15",
      "ocr_confidence": 95.18,
      "width": 1330,
      "height": 3993,
      "avg_char_width": 28.6144,
      "avg_line_height": 48.138,
      "source_locations": {
        "date": [
          [
            {"y": 3042, "x": 127},
            {"y": 3039, "x": 672},
            {"y": 3111, "x": 672},
            {"y": 3114, "x": 127}
          ]
        ],
        "total": [
          [
            {"y": 2787, "x": 747},
            {"y": 2778, "x": 1069},
            {"y": 2829, "x": 1070},
            {"y": 2839, "x": 748}
          ]
        ],
        "receipt_no": [
          [
            {"y": 3035, "x": 760},
            {"y": 3027, "x": 1016},
            {"y": 3082, "x": 1018},
            {"y": 3090, "x": 762}
          ]
        ],
        "credit_card_number": [
          [
            {"y": 2751, "x": 134},
            {"y": 2740, "x": 471},
            {"y": 2790, "x": 472},
            {"y": 2801, "x": 136}
          ]
        ],
        "merchant_name": [
          [
            {"y": 622, "x": 221},
            {"y": 621, "x": 1244},
            {"y": 684, "x": 1244},
            {"y": 685, "x": 221}
          ]
        ],
        "doc": [
          [
            {"y": 86, "x": 61},
            {"y": 77, "x": 1524},
            {"y": 4470, "x": 1550},
            {"y": 4478, "x": 87}
          ]
        ]
      }
    }
  ]
};
final one = {
  "ocr_type": "receipts",
  "request_id": "P_158.174.19.71_lbxiokyy_wiw",
  "ref_no": "AspDemo_1671618817269_864",
  "file_name": "IMG_20221201_142930.jpg",
  "request_received_on": 1671618815530,
  "success": true,
  "image_width": 4608,
  "image_height": 3456,
  "image_rotation": -1.574,
  "recognition_completed_on": 1671618823103,
  "receipts": [
    {
      "merchant_name": "ICA",
      "merchant_address": null,
      "merchant_phone": null,
      "merchant_website": null,
      "merchant_tax_reg_no": null,
      "merchant_company_reg_no": null,
      "region": null,
      "mall": null,
      "country": "US",
      "receipt_no": "3818",
      "date": "2022-11-10",
      "time": null,
      "items": [
        {
          "amount": 18.90,
          "category": null,
          "description": "Grönsaksbuljong",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 11.09,
          "category": null,
          "description": "Paprika Röd",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 20.00,
          "category": null,
          "description": "Peppkakor SmåHjär",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 15.82,
          "category": null,
          "description": "Potatis fast",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 20.90,
          "category": null,
          "description": "Salladsost",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 14.90,
          "category": null,
          "description": "Svarta bönor",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": -3.80,
          "category": null,
          "description": "Rabatt: bönor 2/26:",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 10.82,
          "category": null,
          "description": "Tomater",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        }
      ],
      "currency": "USD",
      "total": 123.53,
      "subtotal": null,
      "tax": null,
      "service_charge": null,
      "tip": null,
      "payment_method": null,
      "payment_details": null,
      "credit_card_type": "MASTER",
      "credit_card_number": "9716",
      "ocr_text":
          "             ICA\n                     nära\n  FOLKES LIVS\n          Butiken med Uppsalas\n            bästa öppettider!\n  Alltid öppet!!!\n  Säljare: 140         Kassa: 01 Nr: 3818\n Datum: 2022-11-10              Tid: 20:30\n Ref. 4400149801040989341110227\n Grönsaksbuljong                     18,90\n                                      14,90\n *Kidneybönor\n Paprika Röd                          11,09\n Peppkakor SmåHjär                   20,00\n Potatis fast                         15,82\n Salladsost                           20,90\n *Svarta bönor                        14,90\n   Rabatt: bönor 2/26:                -3,80\n Tomater                              10,82\n Total                   123,53 Kr\n Moms%        Moms       Netto       Brutto\n 12,00       13,24      110,29       123,53\n Erhållen rabatt:                      3,80\n Mottaget Kontokort                  123,53\n Term: 1710021797     SWE: 479972\n Debit Mastercard     ************ 9716\n Butik: 1498\n 2022-11-10 20:30     AID: A0000000041010\n TVR: 0000048001      TSI: 0000\n Ref: 002179724294 110 Rsp: 00 186690 K/1 7\n Contactless\n Köp           123,53\n Varav moms     13,24\n Totalt SEK    123,53\n Spara kvittot\n Spara kvittot\n                                     1\n Org.nr. 556780-0668\n Tel: 018-544915\n Mail: agneta.johnsen@nara.ica.se\n Hemsida: folkeslivs.se\n *Vi har en onlinebutik på vår hemsida!*\n ** 20% rabatt på första köpet **\n ** Hemleverans från 10 kr **\n ** Alla varor på en plats **",
      "ocr_confidence": 98.25,
      "width": 1490,
      "height": 4058,
      "avg_char_width": 34.681,
      "avg_line_height": 65.5439,
      "source_locations": {
        "date": [
          [
            {"y": 2309, "x": 1080},
            {"y": 1944, "x": 1078},
            {"y": 1944, "x": 1168},
            {"y": 2309, "x": 1169}
          ]
        ],
        "total": [
          [
            {"y": 1734, "x": 1996},
            {"y": 1066, "x": 1970},
            {"y": 1063, "x": 2040},
            {"y": 1731, "x": 2067}
          ]
        ],
        "receipt_no": [
          [
            {"y": 1279, "x": 984},
            {"y": 1127, "x": 973},
            {"y": 1121, "x": 1048},
            {"y": 1273, "x": 1060}
          ]
        ],
        "merchant_name": [
          [
            {"y": 2175, "x": 242},
            {"y": 1534, "x": 242},
            {"y": 1534, "x": 543},
            {"y": 2174, "x": 543}
          ]
        ],
        "doc": [
          [
            {"y": 2654, "x": 45},
            {"y": 1015, "x": 40},
            {"y": 1000, "x": 4504},
            {"y": 2639, "x": 4510}
          ]
        ]
      }
    }
  ]
};

final three = {
  "ocr_type": "receipts",
  "request_id": "P_158.174.19.71_lbxis22j_kq5",
  "ref_no": "AspDemo_1671618979652_754",
  "file_name": "DSC_0337.JPG",
  "request_received_on": 1671618977659,
  "success": true,
  "image_width": 5504,
  "image_height": 3096,
  "image_rotation": -1.560,
  "recognition_completed_on": 1671618985243,
  "receipts": [
    {
      "merchant_name": "FOLKES LIVS",
      "merchant_address": null,
      "merchant_phone": null,
      "merchant_website": null,
      "merchant_tax_reg_no": null,
      "merchant_company_reg_no": null,
      "region": null,
      "mall": null,
      "country": "US",
      "receipt_no": "5201",
      "date": "2022-02-05",
      "time": null,
      "items": [
        {
          "amount": 25.80,
          "category": null,
          "description": "Arla Mellanfil",
          "flags": "",
          "qty": 2,
          "remarks": null,
          "tags": null,
          "unitPrice": 12.90
        },
        {
          "amount": 27.90,
          "category": null,
          "description": "Gårdsg norm.salt",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 27.80,
          "category": null,
          "description": "Pan Pizza Halloumi",
          "flags": "",
          "qty": 2,
          "remarks": null,
          "tags": null,
          "unitPrice": 13.90
        },
        {
          "amount": 31.45,
          "category": null,
          "description": "C,Kr/kg",
          "flags": "",
          "qty": 525,
          "remarks": null,
          "tags": null,
          "unitPrice": 59.90
        },
        {
          "amount": 23.90,
          "category": null,
          "description": "Paprikapulver",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 27.80,
          "category": null,
          "description": "Pizza Vegetaria",
          "flags": "",
          "qty": 2,
          "remarks": null,
          "tags": null,
          "unitPrice": 13.90
        },
        {
          "amount": 23.90,
          "category": null,
          "description": "Sojabönor",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 19.90,
          "category": null,
          "description": "Spiskummin",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 13.90,
          "category": null,
          "description": "Tomatpure tub",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        }
      ],
      "currency": "USD",
      "total": 260.25,
      "subtotal": null,
      "tax": null,
      "service_charge": null,
      "tip": null,
      "payment_method": null,
      "payment_details": null,
      "credit_card_type": "MASTER",
      "credit_card_number": "9716",
      "ocr_text":
          "         FOLKES LIVS\n         Butiken med Uppsalas\n           bästa öppettider!!!\n                 6-23: 31\n Säljare: 141         Kassa: 01 Nr: 5201\n                                Tid: 19:40\n Datum: 2022-02-05\n Re 4400149801036661590205226\n Arla Mellanfil       2st*12,90      25,80\n                                     37,90\n Gårdsg norm.salt\n                                     27,90\n Müsli tranbärspump\n Pan Pizza Halloumi 2st*13,90        27,80\n Paprika Gul\n              C, 525kg*59,90Kr/kg    31,45\n Paprikapulver                       23,90\n Pizza Vegetaria      2st*13,90      27,80\n Sojabönor                           23,90\n Spiskummin                           19,90\n Tomatpure tub                        13,90\n Total                   260,25 Kr\n Moms%                   Netto       Brutto\n 12.00      27,59      232,37        260,25\n Mo taget Kontokort                  260,25\n Term: 4583-034003    SWE: 479972\n MasterCard           ************ 9716\n 05/02/2022 19:40    AID: A0000000041010\n TVR: 0000048000      TSI: 0000\n Re: 281627953643 086 Rsp: 00 720449 K/1 7\n Contactless\n Köp          260,25\n Varav moms    27,88\n To alt SEK   260,25\n Spara kvittot\n Spara kvittot",
      "ocr_confidence": 95.88,
      "width": 2631,
      "height": 5039,
      "avg_char_width": 60.8135,
      "avg_line_height": 115.2262,
      "source_locations": {
        "date": [
          [
            {"y": 2598, "x": 1282},
            {"y": 1938, "x": 1289},
            {"y": 1940, "x": 1416},
            {"y": 2600, "x": 1409}
          ]
        ],
        "total": [
          [
            {"y": 1606, "x": 3174},
            {"y": 382, "x": 3190},
            {"y": 383, "x": 3312},
            {"y": 1607, "x": 3297}
          ]
        ],
        "receipt_no": [
          [
            {"y": 720, "x": 1116},
            {"y": 444, "x": 1104},
            {"y": 438, "x": 1241},
            {"y": 714, "x": 1253}
          ]
        ],
        "merchant_name": [
          [
            {"y": 2495, "x": 365},
            {"y": 1080, "x": 367},
            {"y": 1080, "x": 575},
            {"y": 2495, "x": 574}
          ]
        ],
        "doc": [
          [
            {"y": 3128, "x": 101},
            {"y": 234, "x": 134},
            {"y": 296, "x": 5677},
            {"y": 3190, "x": 5645}
          ]
        ]
      }
    }
  ]
};

final four = {
  "ocr_type": "receipts",
  "request_id": "P_158.174.19.71_lbxit9on_7hf",
  "ref_no": "AspDemo_1671619036176_292",
  "file_name": "DSC_0336.JPG",
  "request_received_on": 1671619034183,
  "success": true,
  "image_width": 5504,
  "image_height": 3096,
  "image_rotation": -1.560,
  "recognition_completed_on": 1671619041517,
  "receipts": [
    {
      "merchant_name": "FOLKES LIVS",
      "merchant_address": null,
      "merchant_phone": null,
      "merchant_website": null,
      "merchant_tax_reg_no": null,
      "merchant_company_reg_no": null,
      "region": null,
      "mall": null,
      "country": "US",
      "receipt_no": "2291",
      "date": "2022-02-10",
      "time": null,
      "items": [
        {
          "amount": 25.80,
          "category": null,
          "description": "Arla Mellanfil",
          "flags": "",
          "qty": 2,
          "remarks": null,
          "tags": null,
          "unitPrice": 12.90
        },
        {
          "amount": 8.90,
          "category": null,
          "description": "Kidneybönor",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 8.90,
          "category": null,
          "description": "Kikärtor",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 19.90,
          "category": null,
          "description": "Morot nyskördade",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 7.34,
          "category": null,
          "description": "Palsternacka",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 27.80,
          "category": null,
          "description": "Pan Pizza chili ch",
          "flags": "",
          "qty": 2,
          "remarks": null,
          "tags": null,
          "unitPrice": 13.90
        },
        {
          "amount": 27.80,
          "category": null,
          "description": "Pizza Vegetaria",
          "flags": "",
          "qty": 2,
          "remarks": null,
          "tags": null,
          "unitPrice": 13.90
        },
        {
          "amount": 9.40,
          "category": null,
          "description": "Potatis fast",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 22.90,
          "category": null,
          "description": "Röda linser",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 8.90,
          "category": null,
          "description": "S ora vita bönor",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": -5.60,
          "category": null,
          "description": "Rabatt: bönor 2/15:",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 8.90,
          "category": null,
          "description": "Svarta bönor",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 31.93,
          "category": null,
          "description": "Apple Jonagolc",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        }
      ],
      "currency": "USD",
      "total": 202.87,
      "subtotal": null,
      "tax": null,
      "service_charge": null,
      "tip": null,
      "payment_method": null,
      "payment_details": null,
      "credit_card_type": "MASTER",
      "credit_card_number": "9716",
      "ocr_text":
          "         FOLKES LIVS\n         Butiken med Uppsalas\n           bästa öppettider!!!\n                 6-23: 31\n Säljare: 86          Kassa: 01   Nr: 2291\n Datum: 2022-02-10              Tid: 15:15\n Re 4400149801036736690210228\n Arla Mellanfil       2st*12,90      25,80\n *Kidneybönor                         8,90\n *Kikärtor                            8,90\n Morot nyskördade                    19,90\n Palsternacka                         7,34\n Pan Pizza chili ch   2st*13,90      27,80\n Pizza Vegetaria      2st*13,90      27,80\n Potatis fast                         9,40\n Röda linser                         22,90\n *S ora vita bönor                    8,90\n  Rabatt: bönor 2/15:                -5,60\n *Svarta bönor                        8,90\n Apple Jonagolc                      31,93\n                    1\n Total                  202,87 Kr\n Mons%                  Netto        Brutto\n 12.00      21,72      181,15       202,87\n Erhållen rabatt:                      5,60\n Mo taget Kontokort                 202,87\n Term: 4583-034003   SWE: 479972\n MasterCard          ************ 9716\n 10/02/2022 15:15    AID: A0000000041010\n TVR: 0000048000     TSI: 0000\n Re 281627960712 091 Rsp: 00 833781 K/1 7\n Contactless\n              202,87\n varav moms    21,72\n Totalt SEK   202,87\n Spara kvittot\n Spara kvittot",
      "ocr_confidence": 96.09,
      "width": 2401,
      "height": 5083,
      "avg_char_width": 55.8368,
      "avg_line_height": 104.7631,
      "source_locations": {
        "date": [
          [
            {"y": 2386, "x": 1189},
            {"y": 1767, "x": 1195},
            {"y": 1769, "x": 1315},
            {"y": 2388, "x": 1308}
          ]
        ],
        "total": [
          [
            {"y": 1482, "x": 3210},
            {"y": 347, "x": 3233},
            {"y": 349, "x": 3349},
            {"y": 1484, "x": 3326}
          ]
        ],
        "receipt_no": [
          [
            {"y": 638, "x": 1072},
            {"y": 370, "x": 1067},
            {"y": 368, "x": 1191},
            {"y": 636, "x": 1196}
          ]
        ],
        "merchant_name": [
          [
            {"y": 2281, "x": 329},
            {"y": 954, "x": 362},
            {"y": 959, "x": 558},
            {"y": 2286, "x": 526}
          ]
        ],
        "doc": [
          [
            {"y": 2866, "x": 77},
            {"y": 224, "x": 106},
            {"y": 285, "x": 5698},
            {"y": 2927, "x": 5669}
          ]
        ]
      }
    }
  ]
};

final five = {
  "ocr_type": "receipts",
  "request_id": "P_158.174.19.71_lbxiuws3_uan",
  "ref_no": "AspDemo_1671619111934_471",
  "file_name": "DSC_0335.JPG",
  "request_received_on": 1671619110771,
  "success": true,
  "image_width": 5504,
  "image_height": 3096,
  "image_rotation": -1.562,
  "recognition_completed_on": 1671619117621,
  "receipts": [
    {
      "merchant_name": "FOLKES LIVS",
      "merchant_address": null,
      "merchant_phone": null,
      "merchant_website": null,
      "merchant_tax_reg_no": null,
      "merchant_company_reg_no": null,
      "region": null,
      "mall": null,
      "country": "US",
      "receipt_no": "4554",
      "date": "2022-02-11",
      "time": null,
      "items": [
        {
          "amount": 11.90,
          "category": null,
          "description": "Hayremat",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 16.90,
          "category": null,
          "description": "Körsbärstomat",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 14.93,
          "category": null,
          "description": "Svamp Champinjon",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        }
      ],
      "currency": "USD",
      "total": 43.73,
      "subtotal": null,
      "tax": null,
      "service_charge": null,
      "tip": null,
      "payment_method": null,
      "payment_details": null,
      "credit_card_type": null,
      "credit_card_number": "9716",
      "ocr_text":
          "         FOLKES LIVS\n         Butiken med Uppsalas\n           bästa öppettider!!!\n                 6-23: 31\n Saljare: 137         Kassa: 01 Nr: 4554\n Datum: 2022-02-11              Tid: 21:18\n Re 4400149801036760590211227\n Hayremat                             11,90\n Körsbärstomat                        16,90\n Svamp Champinjon                     14,93\n Total                    43,73 Kr\n Mons%                  Netto       Brutto\n 12.00       4,69       39,04         43,73\n Moctaget Kontokort                   43,73\n Term: 4583-034003   SWE: 479972\n MactorCard          ************ 9716\n 11/02/2022 21:10        : A0000000041010\n TVR: 0000048000     TSI: 0000\n Re: 281627962960 092 Rsp: 00 684821 K/1 7\n Contactless\n Köp            43,73\n Varav moms     4,69\n Totalt SEK    43,73\n Spara kvittot\n Spara kvittot\n         Org.nr. 556780-0668",
      "ocr_confidence": 95.32,
      "width": 2850,
      "height": 4844,
      "avg_char_width": 65.6146,
      "avg_line_height": 121.974,
      "source_locations": {
        "date": [
          [
            {"y": 2573, "x": 1678},
            {"y": 1859, "x": 1684},
            {"y": 1860, "x": 1834},
            {"y": 2574, "x": 1828}
          ]
        ],
        "total": [
          [
            {"y": 1334, "x": 2672},
            {"y": 165, "x": 2680},
            {"y": 167, "x": 2813},
            {"y": 1335, "x": 2806}
          ]
        ],
        "receipt_no": [
          [
            {"y": 500, "x": 1539},
            {"y": 183, "x": 1534},
            {"y": 181, "x": 1676},
            {"y": 498, "x": 1681}
          ]
        ],
        "credit_card_number": [
          [
            {"y": 1690, "x": 3534},
            {"y": 476, "x": 3568},
            {"y": 481, "x": 3695},
            {"y": 1693, "x": 3661}
          ]
        ],
        "merchant_name": [
          [
            {"y": 2472, "x": 646},
            {"y": 869, "x": 647},
            {"y": 869, "x": 910},
            {"y": 2473, "x": 910}
          ]
        ],
        "doc": [
          [
            {"y": 3144, "x": 397},
            {"y": 8, "x": 424},
            {"y": 55, "x": 5753},
            {"y": 3191, "x": 5725}
          ]
        ]
      }
    }
  ]
};

final six = {
  "ocr_type": "receipts",
  "request_id": "P_158.174.19.71_lbxiw06h_o0",
  "ref_no": "AspDemo_1671619163047_111",
  "file_name": "DSC_0334.JPG",
  "request_received_on": 1671619161833,
  "success": true,
  "image_width": 5504,
  "image_height": 3096,
  "image_rotation": -1.571,
  "recognition_completed_on": 1671619168759,
  "receipts": [
    {
      "merchant_name": "FOLKES LIVS",
      "merchant_address": null,
      "merchant_phone": null,
      "merchant_website": null,
      "merchant_tax_reg_no": null,
      "merchant_company_reg_no": null,
      "region": null,
      "mall": null,
      "country": "US",
      "receipt_no": "9075",
      "date": "2022-02-14",
      "time": null,
      "items": [
        {
          "amount": 25.80,
          "category": null,
          "description": "Arla Mellanfil",
          "flags": "",
          "qty": 2,
          "remarks": null,
          "tags": null,
          "unitPrice": 12.90
        },
        {
          "amount": 37.90,
          "category": null,
          "description": "Grötbröd",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 11.90,
          "category": null,
          "description": "Havremat",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 29.21,
          "category": null,
          "description": "ICA App Rubinstar",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 8.90,
          "category": null,
          "description": "Kikärtor",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 18.01,
          "category": null,
          "description": "C,Kr/kg",
          "flags": "",
          "qty": 516,
          "remarks": null,
          "tags": null,
          "unitPrice": 34.90
        },
        {
          "amount": 8.90,
          "category": null,
          "description": "Stora vita bönor",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": -2.80,
          "category": null,
          "description": "Rabatt: bönor 2/15:",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 21.90,
          "category": null,
          "description": "Vegetarisk Pastej",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        },
        {
          "amount": 20.90,
          "category": null,
          "description": "vitvinsvinäger gl",
          "flags": "",
          "qty": null,
          "remarks": null,
          "tags": null,
          "unitPrice": null
        }
      ],
      "currency": "USD",
      "total": 180.62,
      "subtotal": null,
      "tax": null,
      "service_charge": null,
      "tip": null,
      "payment_method": null,
      "payment_details": null,
      "credit_card_type": "MASTER",
      "credit_card_number": "9716",
      "ocr_text":
          "          FOLKES LIVS\n          Butiken med Uppsalas\n           bästa öppettider!!!\n                 6-23: 31\n Saljare: 114         Kassa: 01 Nr: 9075\n      : 2022-02-14              Tid: 23:04\n Re 4400149801036808870214226\n Arla Mellanfil       2st*12,90      25,80\n Grötbröd                            37,90\n Havremat                             11,90\n ICA App Rubinstar                    29,21\n *Kikärtor                             8,90\n Rotselleri delad\n             C, 516kg*34,90Kr/kg      18,01\n *Stora vita bönor                     8,90\n  Rabatt: bönor 2/15:                 -2,80\n Vegetarisk Pastej                    21,90\n vitvinsvinäger gl                    20,90\n Total                   180,62 Kr\n Mons        MOTS        Netto       Brutto\n 12.00      19,35       161,27       180,62\n Erhållen rabatt:                      2,80\n Moctaget Kontokort                  180,62\n Term: 4583-034003    SWE: 479972\n MasterCard           ************ 9716\n 14/02/2022 23:04     AID: A0000000041010\n TVR: 0000048000      TSI: 0000\n Re: 281627967492 095 Rsp: 00 290237 K/1 7\n Contactless\n               180,62\n Varay moms     19,35\n To alt SEK    180,62\n Spara kvittot\n Spara kvittot",
      "ocr_confidence": 95.06,
      "width": 2381,
      "height": 4875,
      "avg_char_width": 54.1583,
      "avg_line_height": 102.5079,
      "source_locations": {
        "date": [
          [
            {"y": 2373, "x": 1461},
            {"y": 1762, "x": 1461},
            {"y": 1762, "x": 1584},
            {"y": 2373, "x": 1584}
          ]
        ],
        "total": [
          [
            {"y": 1450, "x": 3169},
            {"y": 335, "x": 3183},
            {"y": 336, "x": 3299},
            {"y": 1451, "x": 3286}
          ]
        ],
        "receipt_no": [
          [
            {"y": 667, "x": 1313},
            {"y": 421, "x": 1307},
            {"y": 418, "x": 1424},
            {"y": 664, "x": 1430}
          ]
        ],
        "merchant_name": [
          [
            {"y": 2283, "x": 619},
            {"y": 992, "x": 556},
            {"y": 982, "x": 762},
            {"y": 2273, "x": 825}
          ]
        ],
        "doc": [
          [
            {"y": 2874, "x": 322},
            {"y": 254, "x": 320},
            {"y": 251, "x": 5683},
            {"y": 2870, "x": 5685}
          ]
        ]
      }
    }
  ]
};
